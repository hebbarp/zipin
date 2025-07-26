// ZipIn Service Worker
// Provides offline functionality and faster loading

const CACHE_NAME = 'zipin-v4';
const urlsToCache = [
  '/',
  '/assets/app.css',
  '/assets/app.js',
  '/manifest.json',
  '/offline.html'
];

// Install event - cache important resources
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('SW: Cache opened');
        // Cache files individually to handle failures gracefully
        return Promise.allSettled(
          urlsToCache.map(url => 
            cache.add(url).catch(err => {
              console.warn('SW: Failed to cache', url, err);
              return null;
            })
          )
        );
      })
      .then(() => {
        console.log('SW: Initial caching completed');
        // Skip waiting and activate immediately
        return self.skipWaiting();
      })
  );
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', function(event) {
  // Skip caching for non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  // Skip caching for websocket connections
  if (event.request.url.includes('live/websocket')) {
    return;
  }

  // Skip caching for authentication routes
  if (event.request.url.includes('/auth/')) {
    return;
  }

  // Skip caching for routes that commonly redirect
  if (event.request.url.includes('/stream')) {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Return cached version if available
        if (response) {
          return response;
        }

        // Fetch from network with proper redirect handling
        return fetch(event.request, {
          redirect: 'follow'
        }).then(function(response) {
          // Don't cache redirects or non-successful responses
          if (!response || response.status !== 200 || response.type !== 'basic' || response.redirected) {
            return response;
          }

          // Clone the response
          var responseToCache = response.clone();

          // Cache static assets and main pages only
          if (event.request.url.includes('/assets/') || 
              event.request.url.includes('/places') ||
              event.request.url.includes('/events') ||
              event.request.url.includes('/explore')) {
            caches.open(CACHE_NAME)
              .then(function(cache) {
                cache.put(event.request, responseToCache);
              });
          }

          return response;
        }).catch(function() {
          // If both cache and network fail, show offline page for navigation requests
          if (event.request.destination === 'document') {
            return caches.match('/offline.html');
          }
        });
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            console.log('SW: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Background sync for offline posts
self.addEventListener('sync', function(event) {
  if (event.tag === 'background-sync') {
    console.log('SW: Background sync triggered');
    // This would sync offline posts when connection is restored
    event.waitUntil(syncOfflinePosts());
  }
});

// Push notifications for events and messages
self.addEventListener('push', function(event) {
  if (event.data) {
    const data = event.data.json();
    const options = {
      body: data.body,
      icon: '/images/icon-192x192.png',
      badge: '/images/badge-72x72.png',
      tag: data.tag,
      data: data,
      actions: [
        {
          action: 'view',
          title: 'View',
          icon: '/images/action-view.png'
        },
        {
          action: 'dismiss',
          title: 'Dismiss',
          icon: '/images/action-dismiss.png'
        }
      ]
    };

    event.waitUntil(
      self.registration.showNotification(data.title, options)
    );
  }
});

// Handle notification clicks
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  if (event.action === 'view') {
    event.waitUntil(
      clients.openWindow(event.notification.data.url || '/stream')
    );
  }
});

// Sync offline posts when connection is restored
async function syncOfflinePosts() {
  try {
    // This would implement offline post synchronization
    console.log('SW: Syncing offline posts...');
    
    // Get offline posts from IndexedDB
    // Send them to server
    // Clear from IndexedDB on success
    
    console.log('SW: Offline posts synced');
  } catch (error) {
    console.error('SW: Error syncing offline posts:', error);
  }
}