importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyB9fJ0RDjkF95y2EwB_TinhwaYHmbznWyw",
    authDomain: "pizza-lamia-app.firebaseapp.com",
    projectId: "pizza-lamia-app",
    storageBucket: "pizza-lamia-app.firebasestorage.app",
    messagingSenderId: "171001688842",
    appId: "1:171001688842:web:a57f94f9fe4aad3e63c0f3",
    measurementId: "G-ZDFG95KZZC"
});

const messaging = firebase.messaging();
