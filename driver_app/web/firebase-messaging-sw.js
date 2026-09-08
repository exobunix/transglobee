importScripts('https://www.gstatic.com/firebasejs/9.1.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyC7SGsD3I7EOEKDh8VXchJGSYz6dnLqM4I",
  authDomain: "mera-ubar.firebaseapp.com",
  projectId: "mera-ubar",
  storageBucket: "mera-ubar.firebasestorage.app",
  messagingSenderId: "1072284227316",
  appId: "1:1072284227316:web:f7c08816b810cc00cd30a1",
  measurementId: "G-1BETFQFRZV"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
