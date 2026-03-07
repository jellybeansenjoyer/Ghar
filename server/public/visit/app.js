// Ghar Visitor Web Form Application
(function () {
  'use strict';

  // Extract familyId from URL path: /visit/:familyId
  const pathParts = window.location.pathname.split('/');
  const familyId = pathParts[pathParts.length - 1];

  if (!familyId || familyId === 'visit') {
    alert('Invalid link. Please scan the QR code again.');
    return;
  }

  // API base URL (same origin)
  const API_BASE = window.location.origin;

  // State
  let visitorId = null;
  let visitorName = '';
  let socket = null;
  let photoFile = null;

  // DOM Elements
  const formPage = document.getElementById('formPage');
  const waitingPage = document.getElementById('waitingPage');
  const responsePage = document.getElementById('responsePage');
  const chatPage = document.getElementById('chatPage');

  const visitorForm = document.getElementById('visitorForm');
  const nameInput = document.getElementById('visitorName');
  const photoInput = document.getElementById('visitorPhoto');
  const photoPreview = document.getElementById('photoPreview');
  const submitBtn = document.getElementById('submitBtn');
  const submitText = document.getElementById('submitText');
  const submitLoader = document.getElementById('submitLoader');

  const responseIcon = document.getElementById('responseIcon');
  const responseTitle = document.getElementById('responseTitle');
  const responseMessage = document.getElementById('responseMessage');

  const chatMessages = document.getElementById('chatMessages');
  const chatInput = document.getElementById('chatInput');
  const chatSendBtn = document.getElementById('chatSendBtn');

  // Pages navigation
  function showPage(page) {
    [formPage, waitingPage, responsePage, chatPage].forEach(function (p) {
      p.classList.remove('active');
    });
    page.classList.add('active');
  }

  // Photo handling
  photoInput.addEventListener('change', function (e) {
    const file = e.target.files[0];
    if (file) {
      photoFile = file;
      const reader = new FileReader();
      reader.onload = function (event) {
        photoPreview.innerHTML = '<img src="' + event.target.result + '" alt="Your photo">';
        photoPreview.classList.add('has-photo');
      };
      reader.readAsDataURL(file);
    }
  });

  // Form submission
  visitorForm.addEventListener('submit', async function (e) {
    e.preventDefault();

    visitorName = nameInput.value.trim();
    if (!visitorName) {
      nameInput.focus();
      return;
    }

    // Disable button and show loader
    submitBtn.disabled = true;
    submitText.classList.add('hidden');
    submitLoader.classList.remove('hidden');

    try {
      const formData = new FormData();
      formData.append('familyId', familyId);
      formData.append('name', visitorName);
      if (photoFile) {
        formData.append('photo', photoFile);
      }

      const response = await fetch(API_BASE + '/api/visitors', {
        method: 'POST',
        body: formData,
      });

      const result = await response.json();

      if (!result.success) {
        throw new Error(result.message || 'Failed to register');
      }

      visitorId = result.data.visitorId;

      // Show waiting page
      showPage(waitingPage);

      // Connect Socket.IO for real-time updates
      connectSocket();
    } catch (error) {
      alert(error.message || 'Something went wrong. Please try again.');
      submitBtn.disabled = false;
      submitText.classList.remove('hidden');
      submitLoader.classList.add('hidden');
    }
  });

  // Socket.IO connection
  function connectSocket() {
    socket = io(API_BASE, {
      transports: ['websocket', 'polling'],
    });

    socket.on('connect', function () {
      console.log('Connected to server');
      // Join visitor room
      socket.emit('join:visitor', { visitorId: visitorId });
    });

    // Listen for visitor status updates
    socket.on('visitor:status', function (data) {
      handleResponse(data.status, data.respondedBy);
    });

    // Listen for chat messages
    socket.on('chat:message', function (data) {
      if (data.senderType !== 'visitor') {
        addChatMessage(data.content, data.senderName, false);
      }
    });

    // Listen for expiry
    socket.on('visitor:expired', function () {
      handleResponse('expired', null);
    });

    socket.on('disconnect', function () {
      console.log('Disconnected from server');
    });
  }

  // Handle response from family
  function handleResponse(status, respondedBy) {
    if (status === 'accepted') {
      responseIcon.textContent = '✅';
      responseTitle.textContent = 'Welcome!';
      responseMessage.textContent = (respondedBy || 'A family member') + ' has welcomed you. Please come in!';
      showPage(responsePage);

      // Show chat option after a moment
      setTimeout(function () {
        showPage(chatPage);
      }, 3000);
    } else if (status === 'rejected') {
      responseIcon.textContent = '😔';
      responseTitle.textContent = 'Not Available';
      responseMessage.textContent = 'The family is not available right now. Please try again later.';
      showPage(responsePage);
    } else if (status === 'expired') {
      responseIcon.textContent = '⏰';
      responseTitle.textContent = 'No Response';
      responseMessage.textContent = 'No one responded. They might be away. Please try again later.';
      showPage(responsePage);
    }
  }

  // Chat functionality
  function addChatMessage(content, senderName, isSent) {
    var msgDiv = document.createElement('div');
    msgDiv.className = 'chat-msg ' + (isSent ? 'sent' : 'received');

    if (!isSent) {
      var senderDiv = document.createElement('div');
      senderDiv.className = 'msg-sender';
      senderDiv.textContent = senderName;
      msgDiv.appendChild(senderDiv);
    }

    var textNode = document.createTextNode(content);
    msgDiv.appendChild(textNode);
    chatMessages.appendChild(msgDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  async function sendChatMessage() {
    var message = chatInput.value.trim();
    if (!message || !visitorId) return;

    chatInput.value = '';
    addChatMessage(message, visitorName, true);

    try {
      await fetch(API_BASE + '/api/visitors/' + visitorId + '/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          content: message,
          senderType: 'visitor',
          senderName: visitorName,
        }),
      });
    } catch (error) {
      console.error('Failed to send message:', error);
    }
  }

  chatSendBtn.addEventListener('click', sendChatMessage);
  chatInput.addEventListener('keypress', function (e) {
    if (e.key === 'Enter') {
      sendChatMessage();
    }
  });
})();
