"use strict";
(() => {
  const body = document.body;
  const sidebar = document.querySelector(".sidebar");
  const menu = document.querySelector(".menu-button");
  const closeNav = () => {
    body.classList.remove("nav-open");
    menu?.setAttribute("aria-expanded", "false");
  };
  if (sidebar && !document.querySelector(".nav-backdrop")) {
    const backdrop = document.createElement("button");
    backdrop.type = "button";
    backdrop.className = "nav-backdrop";
    backdrop.setAttribute("aria-label", "Close navigation");
    backdrop.addEventListener("click", closeNav);
    document.querySelector(".app-shell")?.appendChild(backdrop);
  }
  menu?.addEventListener("click", () => {
    const open = !body.classList.contains("nav-open");
    body.classList.toggle("nav-open", open);
    menu.setAttribute("aria-expanded", String(open));
  });

  const current = location.pathname.replace(/\/+$/, "");
  document.querySelectorAll(".nav a").forEach((link) => {
    const path = new URL(link.href, location.href).pathname.replace(/\/+$/, "");
    if (path === current) {
      link.classList.add("is-active");
      link.setAttribute("aria-current", "page");
    }
    link.addEventListener("click", () => {
      if (matchMedia("(max-width: 900px)").matches) closeNav();
    });
  });

  // Descriptive hover/focus previews never navigate; clicking/Enter still opens the link.
  const preview = document.querySelector(".nav-preview");
  document.querySelectorAll(".nav a, .actions a, .shortcut-grid a").forEach((link) => {
    if (!link.dataset.preview) link.dataset.preview = `${link.textContent.trim()} — open this workspace.`;
    const show = () => {
      if (!preview || matchMedia("(max-width: 900px)").matches) return;
      const box = link.getBoundingClientRect();
      preview.textContent = link.dataset.preview;
      preview.hidden = false;
      const sidebarLink = !!link.closest(".sidebar");
      preview.style.left = `${sidebarLink ? box.right + 12 : Math.min(box.left, innerWidth - 340)}px`;
      preview.style.top = `${Math.min(box.top, innerHeight - preview.offsetHeight - 18)}px`;
    };
    const hide = () => { if (preview) preview.hidden = true; };
    link.addEventListener("mouseenter", show);
    link.addEventListener("focus", show);
    link.addEventListener("mouseleave", hide);
    link.addEventListener("blur", hide);
  });

  const numeric = (value) => Number(String(value).replace(/,/g, "")) || 0;
  const formatMoney = (value, decimals = 2) => new Intl.NumberFormat("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);
  document.querySelectorAll(".money-input").forEach((input) => {
    input.addEventListener("focus", () => { input.value = input.value.replace(/,/g, ""); });
    input.addEventListener("blur", () => {
      const value = numeric(input.value);
      input.value = value ? new Intl.NumberFormat("en-US", { maximumFractionDigits: 2 }).format(value) : "";
    });
  });
  document.querySelectorAll("[data-fx-rate]").forEach((form) => {
    const rate = Number(form.dataset.fxRate);
    const update = (amount) => {
      const container = amount.closest(".pricing-entry");
      const currency = container?.querySelector(".offer-currency")?.value || "TZS";
      const output = container?.querySelector(".offer-equivalent");
      const value = numeric(amount.value);
      if (!output) return;
      if (!value || !rate) output.textContent = "Enter an amount to see the equivalent.";
      else if (currency === "TZS") output.textContent = `Equivalent: USD ${formatMoney(value / rate)}`;
      else output.textContent = `Equivalent: TZS ${formatMoney(value * rate)}`;
    };
    form.querySelectorAll(".offer-amount").forEach((amount) => {
      amount.addEventListener("input", () => update(amount));
      amount.closest(".pricing-entry")?.querySelector(".offer-currency")?.addEventListener("change", () => update(amount));
    });
  });

  const targetType = document.querySelector(".notification-target-type");
  const syncTarget = () => {
    if (!targetType) return;
    document.querySelectorAll(".notification-target").forEach((field) => {
      const active = field.classList.contains(targetType.value);
      field.hidden = !active;
      const control = field.querySelector("input,select");
      if (control) {
        if (active) control.setAttribute("name", "target");
        else control.removeAttribute("name");
      }
    });
  };
  targetType?.addEventListener("change", syncTarget);
  syncTarget();

  document.querySelectorAll("form.notification-action").forEach((form) => {
    form.addEventListener("submit", () => {
      const field = form.querySelector('[name="scroll_y"]');
      if (field) field.value = String(Math.round(scrollY));
    });
  });
  const scroll = Number(new URLSearchParams(location.search).get("scroll"));
  if (scroll > 0) requestAnimationFrame(() => scrollTo({ top: scroll, behavior: "instant" }));

  const assistant = document.querySelector(".assistant-shell");
  const assistantButton = assistant?.querySelector(".assistant-button");
  const assistantPanel = assistant?.querySelector(".assistant-panel");
  const toggleAssistant = (open) => {
    if (!assistantButton || !assistantPanel) return;
    assistantPanel.hidden = !open;
    assistantButton.setAttribute("aria-expanded", String(open));
  };
  assistantButton?.addEventListener("click", () => toggleAssistant(assistantPanel?.hidden ?? true));
  assistant?.querySelector(".assistant-close")?.addEventListener("click", () => toggleAssistant(false));

  // Lightweight English/Kiswahili interface translation. Dynamic business data is never altered.
  const sw = {
    "Workspace":"Sehemu ya kazi","Operations":"Uendeshaji","Finance":"Fedha","Governance":"Utawala","Carrier":"Msafirishaji","Driver":"Dereva","Shipper":"Mteja wa mizigo",
    "Overview":"Muhtasari","Notifications":"Taarifa","Company":"Kampuni","My profile":"Wasifu wangu","Load queue":"Foleni ya mizigo","Carrier verification":"Uthibitishaji wa wasafirishaji","Truck verification":"Uthibitishaji wa malori","Driver verification":"Uthibitishaji wa madereva","Subscription payments":"Malipo ya usajili","Fleet eligibility":"Ustahiki wa magari","Matching queue":"Foleni ya ulinganishaji","Transport offers":"Ofa za usafiri","Assignments":"Ugawaji","Shipments & Trips":"Shehena na safari","Operations monitoring":"Ufuatiliaji wa uendeshaji","Documents & e-POD":"Nyaraka na e-POD","Payments & Settlements":"Malipo na makubaliano","Audit events":"Matukio ya ukaguzi","Access logs":"Kumbukumbu za ufikiaji","Carrier profile":"Wasifu wa msafirishaji","My trucks":"Malori yangu","My drivers":"Madereva wangu","Subscription":"Usajili","My transport offers":"Ofa zangu za usafiri","My assignments":"Migawo yangu","Fleet trips":"Safari za magari","Settlements":"Makubaliano ya malipo","My trips":"Safari zangu","My loads":"Mizigo yangu","Post a load":"Weka mzigo","Shipments & Documents":"Shehena na nyaraka","Payments":"Malipo",
    "Log out":"Ondoka","Welcome back":"Karibu tena","Secure workspace":"Sehemu salama ya kazi","Email address":"Barua pepe","Password":"Nenosiri","Enter secure workspace":"Ingia kwenye mfumo salama","Create account":"Fungua akaunti","Already have an account?":"Tayari una akaunti?","About the platform":"Kuhusu jukwaa","Open notifications":"Fungua taarifa","About McCollins":"Kuhusu McCollins","Close":"Funga","Mark as read":"Weka kama imesomwa","Open":"Fungua","Current plan":"Mpango wa sasa","Choose a plan":"Chagua mpango","Choose a future plan":"Chagua mpango wa baadaye"
  };
  const translate = (lang) => {
    localStorage.setItem("mc-language", lang);
    document.documentElement.lang = lang === "sw" ? "sw" : "en";
    document.querySelectorAll("[data-en][data-sw]").forEach((el) => { el.textContent = lang === "sw" ? el.dataset.sw : el.dataset.en; });
    document.querySelectorAll("[data-i18n]").forEach((el) => { const key = el.dataset.i18n; el.textContent = lang === "sw" && sw[key] ? sw[key] : key; });
    document.querySelectorAll("h1,h2,h3,label,button,a,span").forEach((el) => {
      if (el.children.length || el.hasAttribute("data-en") || el.hasAttribute("data-i18n")) return;
      const original = el.dataset.originalEn || el.textContent.trim();
      if (!el.dataset.originalEn && sw[original]) el.dataset.originalEn = original;
      if (el.dataset.originalEn) el.textContent = lang === "sw" ? (sw[el.dataset.originalEn] || el.dataset.originalEn) : el.dataset.originalEn;
    });
    document.querySelectorAll(".language-toggle").forEach((button) => { button.textContent = lang === "sw" ? "English" : "Kiswahili"; button.setAttribute("aria-pressed",String(lang === "sw")); });
  };
  document.querySelectorAll(".language-toggle").forEach((button) => button.addEventListener("click", () => translate((localStorage.getItem("mc-language") || "en") === "en" ? "sw" : "en")));
  translate(localStorage.getItem("mc-language") || "en");

  // Preserve position after same-page form actions and browser return navigation.
  if ("scrollRestoration" in history) history.scrollRestoration = "auto";
  document.querySelectorAll("form").forEach((form) => form.addEventListener("submit", () => {
    if (!form.action.includes("logout.php")) sessionStorage.setItem(`mc-scroll:${location.pathname}`, String(Math.round(scrollY)));
  }));
  const successReturn = /(?:updated|created|requested|sent|payment|activated|revised)=/.test(location.search);
  if (successReturn) {
    const key = `mc-scroll:${location.pathname}`;
    const saved = Number(sessionStorage.getItem(key));
    if (saved > 0) requestAnimationFrame(() => scrollTo({top:saved,behavior:"auto"}));
    sessionStorage.removeItem(key);
  }

  // Existing table wrappers become keyboard-accessible horizontal sliders when content is wide.
  document.querySelectorAll(".table-wrap").forEach((wrap) => {
    if (!wrap.hasAttribute("tabindex")) wrap.tabIndex = 0;
    wrap.setAttribute("aria-label", wrap.getAttribute("aria-label") || (document.documentElement.lang === "sw" ? "Jedwali linalosogezwa kushoto na kulia" : "Horizontally scrollable table"));
    const table = wrap.querySelector("table");
    const columns = table?.querySelectorAll("thead th").length || 0;
    if (table && columns >= 6) table.style.minWidth = `${Math.max(900, columns * 155)}px`;
    wrap.addEventListener("keydown", (event) => {
      if (event.key === "ArrowRight") { wrap.scrollBy({left:140,behavior:"smooth"}); event.preventDefault(); }
      if (event.key === "ArrowLeft") { wrap.scrollBy({left:-140,behavior:"smooth"}); event.preventDefault(); }
    });
    wrap.addEventListener("wheel", (event) => {
      if (event.shiftKey && wrap.scrollWidth > wrap.clientWidth) { wrap.scrollLeft += event.deltaY; event.preventDefault(); }
    }, {passive:false});
  });

  // Premium content carousel: native swipe, drag, controls, dots and slow autoplay.
  document.querySelectorAll(".mc-carousel").forEach((carousel) => {
    const viewport = carousel.querySelector(".mc-carousel-viewport");
    const cards = [...carousel.querySelectorAll(".mc-carousel-card")];
    const dots = carousel.querySelector(".mc-carousel-dots");
    if (!viewport || cards.length === 0 || !dots) return;
    cards.forEach((card, index) => {
      const dot = document.createElement("button");
      dot.type = "button"; dot.className = "mc-carousel-dot";
      dot.setAttribute("role", "tab"); dot.setAttribute("aria-label", `Show capability ${index + 1}`);
      dot.addEventListener("click", () => card.scrollIntoView({behavior:"smooth",block:"nearest",inline:"start"}));
      dots.appendChild(dot);
    });
    const dotList = [...dots.children];
    const activeIndex = () => {
      const left = viewport.scrollLeft;
      return cards.reduce((best, card, index) => Math.abs(card.offsetLeft - left) < Math.abs(cards[best].offsetLeft - left) ? index : best, 0);
    };
    const updateDots = () => { const active = activeIndex(); dotList.forEach((dot,index) => dot.setAttribute("aria-selected",String(index === active))); };
    const go = (direction) => {
      let next = activeIndex() + direction;
      if (next >= cards.length) next = 0;
      if (next < 0) next = cards.length - 1;
      cards[next].scrollIntoView({behavior:"smooth",block:"nearest",inline:"start"});
    };
    carousel.querySelector(".mc-carousel-prev")?.addEventListener("click", () => go(-1));
    carousel.querySelector(".mc-carousel-next")?.addEventListener("click", () => go(1));
    viewport.addEventListener("scroll", () => requestAnimationFrame(updateDots), {passive:true});
    viewport.addEventListener("keydown", (event) => { if(event.key === "ArrowRight"){go(1);event.preventDefault();} if(event.key === "ArrowLeft"){go(-1);event.preventDefault();} });
    let dragging=false,startX=0,startScroll=0;
    viewport.addEventListener("pointerdown",(event)=>{dragging=true;startX=event.clientX;startScroll=viewport.scrollLeft;viewport.classList.add("is-dragging");viewport.setPointerCapture(event.pointerId);});
    viewport.addEventListener("pointermove",(event)=>{if(dragging)viewport.scrollLeft=startScroll-(event.clientX-startX);});
    const stopDrag=()=>{dragging=false;viewport.classList.remove("is-dragging");};
    viewport.addEventListener("pointerup",stopDrag);viewport.addEventListener("pointercancel",stopDrag);
    let timer=null; const reduced=matchMedia("(prefers-reduced-motion: reduce)").matches;
    const stop=()=>{if(timer){clearInterval(timer);timer=null;}};
    const start=()=>{if(!reduced&&!timer)timer=setInterval(()=>go(1),6500);};
    carousel.addEventListener("mouseenter",stop);carousel.addEventListener("mouseleave",start);
    carousel.addEventListener("focusin",stop);carousel.addEventListener("focusout",start);
    document.addEventListener("visibilitychange",()=>document.hidden?stop():start());
    updateDots();start();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") { closeNav(); toggleAssistant(false); }
  });
})();
