// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.DebugTextarea = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      console.log("=== TEXTAREA INPUT EVENT ===")
      console.log("Value length:", e.target.value.length)
      console.log("Value:", e.target.value)
      if (e.target.value.includes("timesofindia")) {
        console.log("=== FOUND TIMES OF INDIA URL ===")
        console.log("Full URL in textarea:", e.target.value)
      }
    })
    
    this.el.addEventListener("paste", (e) => {
      console.log("=== PASTE EVENT ===")
      let paste = (e.clipboardData || window.clipboardData).getData('text')
      console.log("Pasted text:", paste)
      console.log("Pasted text length:", paste.length)
    })
  }
}

Hooks.ThemeManager = {
  mounted() {
    this.initTheme()
    
    window.addEventListener('phx:toggle-dark-mode', () => {
      this.toggleDarkMode()
    })
  },
  
  initTheme() {
    const savedTheme = localStorage.getItem('theme')
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme === 'dark' || (!savedTheme && systemPrefersDark)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  },

  toggleDarkMode() {
    const isDark = document.documentElement.classList.contains('dark')
    if (isDark) {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    } else {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    }
  }
}

// WhatsApp sharing functions for Indian market
window.share_place_whatsapp = function(button) {
  const data = button.dataset
  const placeName = data.placeName
  const placeArea = data.placeArea
  const placeCategory = data.placeCategory
  const placeDescription = data.placeDescription
  const placeRating = data.placeRating
  const placeUrl = data.placeUrl
  
  let message = `🏪 *${placeName}* in ${placeArea}\n\n`
  message += `📍 Category: ${placeCategory.replace('_', ' ')}\n`
  if (placeDescription) {
    message += `💭 ${placeDescription}\n`
  }
  if (placeRating) {
    message += `⭐ Rating: ${placeRating}/5\n`
  }
  message += `\n🔗 Check it out: ${placeUrl}\n\n`
  message += `📲 Found on Cream Social - Bangalore's hyperlocal community!\n`
  message += `#BangaloreLife #${placeArea.replace(' ', '')}`
  
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(message)}`
  window.open(whatsappUrl, '_blank')
}

window.share_event_whatsapp = function(button) {
  const data = button.dataset
  const eventTitle = data.eventTitle
  const eventArea = data.eventArea
  const eventDate = data.eventDate
  const eventVenue = data.eventVenue
  const eventDescription = data.eventDescription  
  const eventUrl = data.eventUrl
  
  let message = `🎉 *${eventTitle}*\n\n`
  message += `📅 When: ${eventDate}\n`
  if (eventVenue) {
    message += `📍 Where: ${eventVenue}`
    if (eventArea) {
      message += `, ${eventArea}`
    }
    message += `\n`
  }
  if (eventDescription) {
    message += `💭 ${eventDescription}\n`
  }
  message += `\n🎫 RSVP here: ${eventUrl}\n\n`
  message += `📲 Found on Cream Social - Join Bangalore events!\n`
  message += `#BangaloreEvents #Community`
  
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(message)}`
  window.open(whatsappUrl, '_blank')
}

window.share_post_whatsapp = function(button) {
  const data = button.dataset
  const postContent = data.postContent
  const postAuthor = data.postAuthor
  const postArea = data.postArea
  const postUrl = data.postUrl
  
  let message = `💬 *Cream Social Post from ${postArea}*\n\n`
  message += `"${postContent}..."\n\n`
  message += `- ${postAuthor}\n\n`
  message += `🔗 Full post: ${postUrl}\n\n`
  message += `📲 Join the conversation on Cream Social!\n`
  message += `#BangaloreTalk #Hyperlocal`
  
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(message)}`
  window.open(whatsappUrl, '_blank')
}

Hooks.Toast = {
  mounted() {
    this.el.addEventListener('phx:toast', (e) => {
      this.showToast(e.detail.message, e.detail.type)
    })
  },

  showToast(message, type = 'info') {
    const toast = document.createElement('div')
    let baseClasses = 'fixed top-4 right-4 text-white px-4 py-2 rounded-lg shadow-lg z-50'
    
    if (type === 'success') {
      baseClasses += ' bg-green-500'
    } else if (type === 'error') {
      baseClasses += ' bg-red-500'
    } else {
      baseClasses += ' bg-blue-500'
    }
    
    toast.className = baseClasses
    toast.textContent = message
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.remove()
    }, 3000)
  }
}

Hooks.Clipboard = {
  mounted() {
    this.el.addEventListener('click', () => {
      const textToCopy = this.el.dataset.clipboardText
      this.copyToClipboard(textToCopy)
    })
  },

  copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(() => {
        this.pushEventTo(this.el, 'toast', { message: 'Link copied! 📋', type: 'success' })
      }).catch(() => {
        this.fallbackCopyTextToClipboard(text)
      })
    } else {
      this.fallbackCopyTextToClipboard(text)
    }
  },

  fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.pushEventTo(this.el, 'toast', { message: 'Link copied! 📋', type: 'success' })
    } catch (err) {
      this.pushEventTo(this.el, 'toast', { message: 'Failed to copy', type: 'error' })
    }
    
    textArea.remove()
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits  
topbar.config({barColors: {0: "#f97316"}, shadowColor: "rgba(0, 0, 0, .3)"})

// Enhanced page loading with flicker prevention
window.addEventListener("phx:page-loading-start", _info => {
  topbar.show(300)
  // Add loading class to prevent flicker
  document.body.classList.add('phx-loading')
})

window.addEventListener("phx:page-loading-stop", _info => {
  topbar.hide()
  // Remove loading class after a brief delay to ensure smooth transition
  setTimeout(() => {
    document.body.classList.remove('phx-loading')
  }, 100)
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// PWA functionality completely removed for simplicity

