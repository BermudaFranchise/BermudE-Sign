self.addEventListener('install', () => {
  console.log('SignSuite App installed')
})

self.addEventListener('activate', () => {
  console.log('SignSuite App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
