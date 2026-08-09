/* ===== Yandex Music - iOS 9 Compatible JS ===== */

var YM = (function() {
    var _token = null;
    var _cbCounter = 0;
    var _pendingCallbacks = {};

    function init() {
        // Wait for token injection from native
        if (window.__YM_TOKEN__) {
            _token = window.__YM_TOKEN__;
            _onReady();
        }
    }

    function _onReady() {
        if (typeof window.onPageReady === 'function') {
            window.onPageReady(_token);
        }
    }

    // Called by native when token is injected
    window.onTokenReady = function() {
        _token = window.__YM_TOKEN__;
        _onReady();
    };

    // Callback for API responses
    window.__ymApiCallback = function(cbId, data) {
        var cb = _pendingCallbacks[cbId];
        if (cb) {
            delete _pendingCallbacks[cbId];
            var parsed;
            try {
                parsed = JSON.parse(data);
            } catch(e) {
                parsed = data;
            }
            cb(parsed);
        }
    };

    // Called by native with player state updates
    window.__ymPlayerUpdate = function(state) {
        if (typeof window.onPlayerUpdate === 'function') {
            window.onPlayerUpdate(state);
        }
    };

    function apiCall(method, path, body, callback) {
        var cbId = 'cb_' + (_cbCounter++);
        _pendingCallbacks[cbId] = callback;
        var msg = {
            method: method || 'GET',
            path: path,
            callbackId: cbId
        };
        if (body) {
            msg.body = body;
        }
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ymapi) {
            window.webkit.messageHandlers.ymapi.postMessage(msg);
        } else {
            // Fallback: XHR direct (for testing in browser)
            _xhrApi(method, path, body, callback);
        }
    }

    function _xhrApi(method, path, body, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, 'https://api.music.yandex.net' + path, true);
        xhr.setRequestHeader('Authorization', 'OAuth ' + _token);
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                try {
                    var json = JSON.parse(xhr.responseText);
                    callback(json);
                } catch(e) {
                    callback({error: xhr.responseText});
                }
            }
        };
        if (body) {
            xhr.send(JSON.stringify(body));
        } else {
            xhr.send();
        }
    }

    function playerAction(action, data, callback) {
        var msg = {action: action};
        if (data) {
            for (var k in data) {
                if (data.hasOwnProperty(k)) {
                    msg[k] = data[k];
                }
            }
        }
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ymplayer) {
            window.webkit.messageHandlers.ymplayer.postMessage(msg);
        }
    }

    function playTrack(track, albumId, queue) {
        var artistName = '';
        if (track.artists && track.artists.length > 0) {
            artistName = track.artists[0].name || '';
        }
        var coverUrl = '';
        if (track.coverUri) {
            coverUrl = 'https://' + track.coverUri.replace('%%', '200x200');
        }
        playerAction('play', {
            trackId: String(track.id),
            title: track.title || '',
            artist: artistName,
            cover: coverUrl,
            duration: track.durationMs ? Math.round(track.durationMs / 1000) : 0,
            albumId: albumId || '',
            queue: queue || null
        });
    }

    function getCoverUrl(coverUri, size) {
        if (!coverUri) return '';
        var s = size || '100x100';
        return 'https://' + coverUri.replace('%%', s);
    }

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0) return '0:00';
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ':' + (s < 10 ? '0' : '') + s;
    }

    function renderTrackList(tracks, containerId, options) {
        var container = document.getElementById(containerId);
        if (!container) return;
        var opts = options || {};
        var html = '';

        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i];
            var artistName = '';
            if (t.artists && t.artists.length > 0) {
                artistName = t.artists[0].name || '';
            }
            var coverSrc = getCoverUrl(t.coverUri);
            var duration = formatDuration(t.durationMs ? t.durationMs / 1000 : 0);
            var albumId = '';
            if (t.albums) {
                var albumKeys = Object.keys(t.albums);
                if (albumKeys.length > 0) {
                    albumId = albumKeys[0];
                }
            }
            var trackJson = encodeURIComponent(JSON.stringify(t));

            html += '<div class="track-item" onclick="YM.onTrackClick(' + i + ')">';
            html += '<div class="track-cover"><img src="' + coverSrc + '" onerror="this.style.display=\'none\'" loading="lazy"></div>';
            html += '<div class="track-info">';
            html += '<div class="track-title">' + escapeHtml(t.title || 'Unknown') + '</div>';
            html += '<div class="track-artist">' + escapeHtml(artistName) + '</div>';
            html += '</div>';
            html += '<div class="track-right">';
            html += '<div class="track-duration">' + duration + '</div>';
            html += '</div>';
            html += '</div>';
        }

        container.innerHTML = html;
        // Store tracks for click handler
        container._tracks = tracks;
    }

    function escapeHtml(text) {
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(text));
        return div.innerHTML;
    }

    function showLoading(containerId) {
        var el = document.getElementById(containerId);
        if (el) {
            el.innerHTML = '<div class="loading"><div class="spinner"></div><br>Загрузка...</div>';
        }
    }

    function showError(containerId, msg) {
        var el = document.getElementById(containerId);
        if (el) {
            el.innerHTML = '<div class="error-msg">' + escapeHtml(msg || 'Ошибка загрузки') + '</div>';
        }
    }

    // Expose
    return {
        init: init,
        apiCall: apiCall,
        playerAction: playerAction,
        playTrack: playTrack,
        getCoverUrl: getCoverUrl,
        formatDuration: formatDuration,
        renderTrackList: renderTrackList,
        showLoading: showLoading,
        showError: showError,
        escapeHtml: escapeHtml,
        getToken: function() { return _token; }
    };
})();

// Auto-init
document.addEventListener('DOMContentLoaded', function() { YM.init(); });
// Also try immediately for WKWebView
if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(function() { YM.init(); }, 50);
}
