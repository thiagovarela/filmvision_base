// assets/js/hooks.js
import { gsap } from "gsap";
// CustomBounce requires CustomEase
import { CustomBounce } from "gsap/CustomBounce";
import { CustomEase } from "gsap/CustomEase";
// CustomWiggle requires CustomEase
import { CustomWiggle } from "gsap/CustomWiggle";
import { Draggable } from "gsap/Draggable";
import { DrawSVGPlugin } from "gsap/DrawSVGPlugin";
import { EaselPlugin } from "gsap/EaselPlugin";
import { ExpoScaleEase, RoughEase, SlowMo } from "gsap/EasePack";
import { Flip } from "gsap/Flip";
import { GSDevTools } from "gsap/GSDevTools";
import { InertiaPlugin } from "gsap/InertiaPlugin";
import { MorphSVGPlugin } from "gsap/MorphSVGPlugin";
import { MotionPathHelper } from "gsap/MotionPathHelper";
import { MotionPathPlugin } from "gsap/MotionPathPlugin";
import { Observer } from "gsap/Observer";
import { Physics2DPlugin } from "gsap/Physics2DPlugin";
import { PhysicsPropsPlugin } from "gsap/PhysicsPropsPlugin";
import { PixiPlugin } from "gsap/PixiPlugin";
import { ScrambleTextPlugin } from "gsap/ScrambleTextPlugin";
// ScrollSmoother requires ScrollTrigger
import { ScrollSmoother } from "gsap/ScrollSmoother";
import { ScrollToPlugin } from "gsap/ScrollToPlugin";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SplitText } from "gsap/SplitText";
import { TextPlugin } from "gsap/TextPlugin";

gsap.registerPlugin(
  Draggable,
  DrawSVGPlugin,
  EaselPlugin,
  Flip,
  GSDevTools,
  InertiaPlugin,
  MotionPathHelper,
  MotionPathPlugin,
  MorphSVGPlugin,
  Observer,
  Physics2DPlugin,
  PhysicsPropsPlugin,
  PixiPlugin,
  ScrambleTextPlugin,
  ScrollTrigger,
  ScrollSmoother,
  ScrollToPlugin,
  SplitText,
  TextPlugin,
  RoughEase,
  ExpoScaleEase,
  SlowMo,
  CustomEase,
  CustomBounce,
  CustomWiggle,
);

export const TypingTextHook = {
  mounted() {
    console.log("TypingTextHook mounted:", this.el);
    this.initTypingAnimation();
  },

  initTypingAnimation() {
    // Check if element exists and has content
    if (!this.el || this.el.textContent.trim() === "") {
      console.log("TypingTextHook: No element or content found");
      return;
    }

    const originalText = this.el.textContent;
    const delay = parseFloat(this.el.dataset.delay || "0");
    const duration = parseFloat(this.el.dataset.duration || "2");
    const triggerNext = this.el.dataset.triggerNext;

    console.log("TypingTextHook: Starting typing effect for:", originalText);

    // Clear the text initially
    this.el.textContent = "";

    // Show the element
    gsap.set(this.el, { opacity: 1 });

    // Use GSAP TextPlugin for typing effect
    gsap.to(this.el, {
      duration: duration,
      text: originalText,
      ease: "none",
      delay: delay,
      onComplete: () => {
        // Trigger next element if specified
        if (triggerNext) {
          this.triggerNextAnimation(triggerNext);
        }
      },
    });
  },

  triggerNextAnimation(selector) {
    const nextElement = document.querySelector(selector);
    if (nextElement) {
      console.log("Triggering animation for:", selector, nextElement);
      // Trigger a custom event on the next element
      nextElement.dispatchEvent(new CustomEvent("animate-in"));
    } else {
      console.log("Element not found:", selector);
    }
  },

  destroyed() {
    gsap.killTweensOf(this.el);
  },
};

export const FadeInHook = {
  mounted() {
    console.log("FadeInHook mounted:", this.el, "ID:", this.el.id);

    const delay = parseFloat(this.el.dataset.delay || "0");
    const duration = parseFloat(this.el.dataset.duration || "1");

    // Start hidden
    gsap.set(this.el, { opacity: 0, y: 20 });

    // Listen for custom animate event
    this.el.addEventListener("animate-in", () => {
      console.log("FadeInHook: Received animate-in event for:", this.el.id);
      this.animateIn(duration);
    });

    // Auto-animate if no trigger specified
    if (!this.el.dataset.waitForTrigger) {
      console.log("FadeInHook: Auto-animating after delay:", delay);
      setTimeout(() => this.animateIn(duration), delay * 1000);
    } else {
      console.log("FadeInHook: Waiting for trigger event");
    }
  },

  animateIn(duration) {
    gsap.to(this.el, {
      opacity: 1,
      y: 0,
      duration: duration,
      ease: "power2.out",
    });
  },

  destroyed() {
    gsap.killTweensOf(this.el);
  },
};

export const Card3DHook = {
  mounted() {
    this.setupCard3D();
  },

  setupCard3D() {
    const card = this.el;

    // Check if element exists
    if (!card) return;

    // Set initial 3D properties
    gsap.set(card, {
      transformPerspective: 1000,
      transformStyle: "preserve-3d",
    });

    // Mouse move 3D effect
    const onMouseMove = (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = ((y - centerY) / centerY) * -15;
      const rotateY = ((x - centerX) / centerX) * 15;

      gsap.to(card, {
        duration: 0.3,
        rotationX: rotateX,
        rotationY: rotateY,
        transformOrigin: "center center -50px",
      });
    };

    const onMouseLeave = () => {
      gsap.to(card, {
        duration: 0.5,
        rotationX: 0,
        rotationY: 0,
        ease: "power2.out",
      });
    };

    card.addEventListener("mousemove", onMouseMove);
    card.addEventListener("mouseleave", onMouseLeave);

    // Store listeners for cleanup
    this.onMouseMove = onMouseMove;
    this.onMouseLeave = onMouseLeave;
  },

  destroyed() {
    if (this.el) {
      this.el.removeEventListener("mousemove", this.onMouseMove);
      this.el.removeEventListener("mouseleave", this.onMouseLeave);
    }
    gsap.killTweensOf(this.el);
  },
};

export const ScrollRevealHook = {
  mounted() {
    this.setupScrollAnimations();
  },

  setupScrollAnimations() {
    // Stagger reveal animation
    const items = this.el.querySelectorAll(".reveal-item");

    // Check if items exist before animating
    if (items.length === 0) return;

    gsap.fromTo(
      items,
      {
        y: 100,
        opacity: 0,
        scale: 0.8,
      },
      {
        duration: 1.2,
        y: 0,
        opacity: 1,
        scale: 1,
        ease: "power3.out",
        stagger: 0.15,
        scrollTrigger: {
          trigger: this.el,
          start: "top 80%",
          end: "bottom 20%",
          toggleActions: "play none none reverse",
        },
      },
    );
  },

  destroyed() {
    ScrollTrigger.getAll().forEach((trigger) => {
      if (trigger.trigger === this.el) {
        trigger.kill();
      }
    });
    gsap.killTweensOf(this.el.querySelectorAll(".reveal-item"));
  },
};

export const MorphingShapeHook = {
  mounted() {
    console.log("MorphingShapeHook mounted:", this.el);
    this.createMorphingAnimation();
  },

  createMorphingAnimation() {
    // Try to find the shape element
    const shape =
      this.el.tagName === "path" ? this.el : this.el.querySelector("path");

    // Check if shape exists before animating
    if (!shape) return;

    const morphTargets = [
      "M50,20 C80,20 80,80 50,80 C20,80 20,20 50,20 Z",
      "M30,40 C70,10 90,60 60,90 C30,70 10,30 30,40 Z",
      "M40,10 C90,30 70,90 20,70 C10,40 20,10 40,10 Z",
    ];

    let currentIndex = 0;

    const animate = () => {
      if (!shape || !shape.isConnected) return;

      currentIndex = (currentIndex + 1) % morphTargets.length;

      gsap.to(shape, {
        duration: 4,
        attr: { d: morphTargets[currentIndex] },
        ease: "power2.inOut",
        onComplete: animate,
      });
    };

    animate();
  },

  destroyed() {
    gsap.killTweensOf(this.el);
  },
};

export const PageTransitionHook = {
  mounted() {
    this.setupTransition();
  },

  setupTransition() {
    // Create overlay for smooth transitions
    const overlay = document.createElement("div");
    overlay.className = "page-transition-overlay";
    overlay.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(45deg, #000, #333);
      z-index: 9999;
      pointer-events: none;
    `;

    document.body.appendChild(overlay);

    // Animate in
    gsap.fromTo(
      overlay,
      { scaleX: 0, transformOrigin: "left center" },
      {
        duration: 0.6,
        scaleX: 1,
        ease: "power2.inOut",
        onComplete: () => {
          gsap.to(overlay, {
            duration: 0.6,
            scaleX: 0,
            transformOrigin: "right center",
            ease: "power2.inOut",
            onComplete: () => overlay.remove(),
          });
        },
      },
    );
  },
};

export const LoaderHook = {
  mounted() {
    // Small delay to ensure DOM is ready
    setTimeout(() => {
      this.initLoader();
    }, 100);
  },

  initLoader() {
    const counter = this.el.querySelector(".loader-counter");
    const progressBar = this.el.querySelector(".loader-progress");

    // Check if elements exist before animating
    if (!counter || !progressBar) {
      console.warn("LoaderHook: Required elements not found");
      // Hide loader immediately if elements are missing
      if (this.el) {
        this.el.style.display = "none";
      }
      return;
    }

    // Counter animation
    gsap.fromTo(
      counter,
      { textContent: 0 },
      {
        textContent: 100,
        duration: 2.5,
        ease: "power2.out",
        snap: { textContent: 1 },
        onUpdate: function () {
          if (counter && counter.isConnected) {
            counter.textContent =
              Math.round(this.targets()[0].textContent) + "%";
          }
        },
      },
    );

    // Progress bar animation
    gsap.fromTo(
      progressBar,
      { width: "0%" },
      {
        width: "100%",
        duration: 2.5,
        ease: "power2.out",
      },
    );

    // Hide loader after animation
    gsap.to(this.el, {
      opacity: 0,
      duration: 0.5,
      delay: 3,
      onComplete: () => {
        if (this.el && this.el.isConnected) {
          this.el.style.display = "none";
        }
      },
    });
  },

  destroyed() {
    gsap.killTweensOf(this.el);
    if (this.el) {
      const counter = this.el.querySelector(".loader-counter");
      const progressBar = this.el.querySelector(".loader-progress");
      if (counter) gsap.killTweensOf(counter);
      if (progressBar) gsap.killTweensOf(progressBar);
    }
  },
};

export const FlashToaster = {
  mounted() {
    this.moveToastsToToaster();
    this.observer = new MutationObserver(() => {
      this.moveToastsToToaster();
    });
    this.observer.observe(this.el, { childList: true, subtree: true });
  },

  moveToastsToToaster() {
    const toaster = document.getElementById("toaster");
    if (!toaster) return;

    const toasts = this.el.querySelectorAll(".toast");
    toasts.forEach((toast) => {
      if (toast.parentNode !== toaster) {
        toaster.appendChild(toast);
      }
    });
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },
};
