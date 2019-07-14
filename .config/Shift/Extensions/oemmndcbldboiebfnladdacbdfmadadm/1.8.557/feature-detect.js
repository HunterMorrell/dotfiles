
    // START-OF-MUON-PATCH

    // Check if we are running in the background page
    function __isBg() {
      return Boolean(window.location.href.match(/^chrome-extension:/))
    }

    // Muon does not support chrome.identity, so we replace it with chrome.tabs
    chrome.identity = chrome.identity || {}
    chrome.identity.launchWebAuthFlow = (options, callback) => {
      chrome.tabs.create({url: options.url}, (createdTab) => {
        let callbackUsed = false
        // Listen to updated tabs to get auth code
        let onTabUpdated = (tabId, changeInfo, updatedTab) => {
          if (updatedTab.url.match(/gaonpiemcjiihedemhopdoefaohcjoch\.chromiumapp\.org/) && !callbackUsed) {
            chrome.tabs.remove(tabId)
            callback(updatedTab.url)
            callbackUsed = true
          }
        }
        chrome.tabs.onUpdated.addListener(onTabUpdated)
        // Listen to removed tabs to callback with error (otherwise UI hangs on)
        let onTabRemoved = (tabId, removeInfo) => {
          if (!callbackUsed) {
            callbackUsed = true
            callback()
          }
        }
        chrome.tabs.onRemoved.addListener(onTabRemoved)
      })
    };

    // Muon doesn't support this method yet.
    // See: https://github.com/brave/browser-laptop/issues/10477
    if (chrome.extension) {
      chrome.extension.isAllowedIncognitoAccess = function(callback) {
        callback(false);
      }
      chrome.extension.isAllowedFileSchemeAccess = function(callback) {
        callback(false);
      }
    }

    if (chrome.tabs) {
      // Needed to facilitate URL matching in chrome.tabs.query
      let escapeRegExp = (str) => str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");

      // Take over tabs.query to fix URL filtering and ignore last-focused.
      let originalQuery = chrome.tabs.query;
      chrome.tabs.query = function(query, callback) {
        // TODO: properly manage focused window state so we don't need this.
        delete query.lastFocusedWindow;

        // URL patterns are not supported in Muon, handle those here.
        let url = query.url;
        delete query.url;

        // Run original query and then manipulate result before invoking callback.
        originalQuery(query, (result) => {
          if (url) {
            url = Array.isArray(url) ? url : [url];
            let pattern = new RegExp(url.map(escapeRegExp).join('|').replace('\*', '.*'));
            result = result.filter((tab) => tab.url.match(pattern));
          }
          callback(result)
        });
      }

      // chrome.windows is not supported by Muon. Replace it by chrome.tabs
      if (chrome.windows) {
        chrome.windows.create = function (options, callback) {
          return chrome.tabs.create({url: options.url}, callback)
        }
        chrome.windows.onRemove = chrome.tabs.onRemove
        chrome.windows.remove = chrome.tabs.remove
      }

      // There's a bug in Muon chrome.tabs.getSelected when its suppose to use the current window, instead Muon tries to
      // set windowId to -2, and that does not work, so we replace the deprecated method by chrome.tabs.query
      chrome.tabs.getSelected = function(windowId, callback) {
        let options = { active: true }
        if (windowId) {
          options.windowId = windowId
        } else {
          options.currentWindow = true
        }
        originalQuery(options, (tabs) => {
          callback(tabs.length ? tabs[0] : undefined)
        })
      }

      // Stub out insertCSS
      // @todo Implement proper support for this
      chrome.tabs.insertCSS = function() {};

      // Replace chrome.tabs.reload by chrome.tabs.update
      chrome.tabs.reload = (id) => {
        chrome.tabs.get(id, (tab) => {
          chrome.tabs.update(tab.id, {url: tab.url})
        })
      }
    }

    // Replace missing api chrome.storage.local with localStorage
    // Normally, chrome.storage.local is sync'd between content-scripts and the BG page
    // Therefore, need to emulate this behavior using message passing (hence the complexity)
    if (chrome.storage) {
      // If we are running in the BG page, listen for requests to get/set storage
      if (__isBg()) {
        chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
          if (request.method === "chrome.storage.local.get") {
            chrome.storage.local.get(request.label, result => sendResponse(result))
          } else if (request.method === "chrome.storage.local.set") {
            chrome.storage.local.set(request.object, result => sendResponse(result))
          }
        });
      }

      chrome.storage.local = {
        get: function (label, resolve) {
          // If we are not running in the BG page, get the value from the BG
          if (!__isBg()) {
            return chrome.runtime.sendMessage(
              { method: "chrome.storage.local.get", label },
              response => resolve(response)
            )
          }

          var data = {}
          if (typeof label == 'string') {
            let value
            try {
              value = JSON.parse(localStorage.getItem(label))
            } catch (err) {
              value = localStorage.getItem(label)
            }
            data[label] = value !== null ? value : undefined
          } else {
            for (let i of label) {
              let value
              try {
                value = JSON.parse(localStorage.getItem(i))
              } catch (err) {
                value = localStorage.getItem(i)
              }
              data[i] = value !== null ? value : undefined
            }
          }

          if (resolve) resolve(data)
        },
        set: function (object, resolve) {
          // If we are not running in the BG page, set the value in the BG
          if (!__isBg()) {
            return chrome.runtime.sendMessage(
              { method: "chrome.storage.local.set", object },
              response => resolve(response)
            )
          }

          for (var property in object) {
            if (object.hasOwnProperty(property)) {
              localStorage.setItem(property, JSON.stringify(object[property]))
            }
          }

          if (resolve) resolve();
        }
      }
      chrome.storage.get = chrome.storage.local.get
      chrome.storage.set = chrome.storage.local.set
      chrome.storage.sync.get = chrome.storage.local.get
      chrome.storage.sync.set = chrome.storage.local.set
    }

    if (chrome.runtime) {
      chrome.runtime.requestUpdateCheck = cb => cb()
    }

    if (chrome.permissions) {
      chrome.permissions.request = (options, cb) => cb(false)
    }

    // Muon supports most of the cookies api, but not getAllCookieStores
    // Since HubSpot (>= 2.8.54) uses this API to check access to cookies
    // we just return an empty cookie store to prevent it from getting stuck
    if (chrome.cookies) {
      chrome.cookies.getAllCookieStores = cb => cb([{}])
      let originalSet = chrome.cookies.set
      chrome.cookies.set = (cookie, cb) => {
        originalSet(cookie, () => {
          chrome.cookies.getAll({ name: cookie.name }, (cookies) => {
            cb(cookies.length && cookies[0])
          })
        })
      }
    }
    
    // Some extensions check if they are running as installed apps and not via bookmark/link
    // This check is not available in Muon, so for our extensions it should be fine to default to true
    chrome.app.isInstalled = false

    // END-OF-MUON-PATCH
    /*
Copyright 2014 Mozilla Foundation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

'use strict';

var Features = {
  featureDetectLastUA: '',
  // Whether ftp: in XMLHttpRequest is allowed
  extensionSupportsFTP: false,
  // Whether redirectUrl at onHeadersReceived is supported.
  webRequestRedirectUrl: false,
};

chrome.storage.local.get(Features, function(features) {
  Features = features;
  if (features.featureDetectLastUA === navigator.userAgent) {
    // Browser not upgraded, so the features did probably not change.
    return;
  }

  // In case of a downgrade, the features must be tested again.
  var lastVersion = /Chrome\/\d+\.0\.(\d+)/.exec(features.featureDetectLastUA);
  lastVersion = lastVersion ? parseInt(lastVersion[1], 10) : 0;
  var newVersion = /Chrome\/\d+\.0\.(\d+)/.exec(navigator.userAgent);
  var isDowngrade = newVersion && parseInt(newVersion[1], 10) < lastVersion;

  var inconclusiveTestCount = 0;

  if (isDowngrade || !features.extensionSupportsFTP) {
    features.extensionSupportsFTP = featureTestFTP();
  }

  if (isDowngrade || !features.webRequestRedirectUrl) {
    ++inconclusiveTestCount;
    // Relatively expensive (and asynchronous) test:
    featureTestRedirectOnHeadersReceived(function(result) {
      // result = 'yes', 'no' or 'maybe'.
      if (result !== 'maybe') {
        --inconclusiveTestCount;
      }
      features.webRequestRedirectUrl = result === 'yes';
      checkTestCompletion();
    });
  }

  checkTestCompletion();

  function checkTestCompletion() {
    // Only stamp the feature detection results when all tests have finished.
    if (inconclusiveTestCount === 0) {
      Features.featureDetectLastUA = navigator.userAgent;
    }
    chrome.storage.local.set(Features);
  }
});

// Tests whether the extension can perform a FTP request.
// Feature is supported since Chromium 35.0.1888.0 (r256810).
function featureTestFTP() {
  var x = new XMLHttpRequest();
  // The URL does not need to exist, as long as the scheme is ftp:.
  x.open('GET', 'ftp://ftp.mozilla.org/');
  try {
    x.send();
    // Previous call did not throw error, so the feature is supported!
    // Immediately abort the request so that the network is not hit at all.
    x.abort();
    return true;
  } catch (e) {
    return false;
  }
}

// Tests whether redirectUrl at the onHeadersReceived stage is functional.
// Feature is supported since Chromium 35.0.1911.0 (r259546).
function featureTestRedirectOnHeadersReceived(callback) {
  // The following URL is really going to be accessed via the network.
  // It is the only way to feature-detect this feature, because the
  // onHeadersReceived event is only triggered for http(s) requests.
  var url = 'http://example.com/?feature-detect-' + chrome.runtime.id;
  function onHeadersReceived(details) {
    // If supported, the request is redirected.
    // If not supported, the return value is ignored.
    return {
      redirectUrl: chrome.runtime.getURL('/manifest.json'),
    };
  }
  chrome.webRequest.onHeadersReceived.addListener(onHeadersReceived, {
    types: ['xmlhttprequest'],
    urls: [url],
  }, ['blocking']);

  var x = new XMLHttpRequest();
  x.open('get', url);
  x.onloadend = function() {
    chrome.webRequest.onHeadersReceived.removeListener(onHeadersReceived);
    if (!x.responseText) {
      // Network error? Anyway, can't tell with certainty whether the feature
      // is supported.
      callback('maybe');
    } else if (/^\s*\{/.test(x.responseText)) {
      // If the response starts with "{", assume that the redirection to the
      // manifest file succeeded, so the feature is supported.
      callback('yes');
    } else {
      // Did not get the content of manifest.json, so the redirect seems not to
      // be followed. The feature is not supported.
      callback('no');
    }
  };
  x.send();
}
