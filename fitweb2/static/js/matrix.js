const matrix = (() => {
  const qs = (selector, root = document) => root.querySelector(selector);
  const qsa = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const state = {
    searchEndpoint: null,
  };

  const getCsrfToken = () => {
    const tokenField = qs("input[name='csrfmiddlewaretoken']");
    if (tokenField && tokenField.value) {
      return tokenField.value;
    }
    const cookie = document.cookie
      .split("; ")
      .find((row) => row.startsWith("csrftoken="));
    return cookie ? decodeURIComponent(cookie.split("=")[1]) : "";
  };

  const initMobileNav = () => {
    const toggle = qs("[data-mobile-toggle]");
    const menu = qs("[data-mobile-menu]");
    if (!toggle || !menu) return;
    toggle.addEventListener("click", () => {
      menu.toggleAttribute("data-open");
      if (menu.hasAttribute("data-open")) {
        menu.style.maxHeight = `${menu.scrollHeight}px`;
      } else {
        menu.style.maxHeight = "0px";
      }
    });
  };

  const updateSearchResults = (html, count) => {
    const target = qs("[data-search-results]");
    const countLabel = qs("[data-search-count]");
    if (target) {
      target.innerHTML = html;
    }
    if (countLabel) {
      countLabel.textContent = String(count);
    }
  };

  const serializeForm = (form) =>
    new URLSearchParams(new FormData(form)).toString();

  const initAsyncSearch = () => {
    const form = qs("[data-async-search]");
    if (!form) return;
    state.searchEndpoint = form.getAttribute("action") || window.location.pathname;
    const submit = async () => {
      const queryString = serializeForm(form);
      const response = await fetch(`${state.searchEndpoint}?${queryString}`, {
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });
      if (!response.ok) return;
      const payload = await response.json();
      updateSearchResults(payload.html, payload.count);
      history.replaceState({}, "", `${state.searchEndpoint}?${queryString}`);
    };
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      submit().catch(() => {});
    });

    qsa("[data-filter-trigger]").forEach((button) => {
      button.addEventListener("click", () => {
        const target = button.dataset.filterTarget;
        const value = button.dataset.filterValue || "";
        if (!target) return;
        const input = qs(`[name='${target}']`, form);
        if (!input) return;
        if (button.dataset.selected === "true") {
          button.dataset.selected = "false";
          input.value = "";
        } else {
          qsa(`[data-filter-trigger][data-filter-target='${target}']`, form).forEach((item) => {
            item.dataset.selected = "false";
          });
          button.dataset.selected = "true";
          input.value = value;
        }
        submit().catch(() => {});
      });
    });
  };

  const initDismissibleToasts = () => {
    qsa("[data-toast-dismiss]").forEach((button) => {
      button.addEventListener("click", () => {
        const toast = button.closest("[data-toast]");
        if (!toast) return;
        toast.classList.add("matrix-toast--hiding");
        toast.addEventListener(
          "transitionend",
          () => toast.remove(),
          { once: true },
        );
      });
    });
  };

  const updateWishlistButton = (button, isActive) => {
    button.dataset.active = isActive ? "true" : "false";
    if (button.hasAttribute("aria-pressed")) {
      button.setAttribute("aria-pressed", isActive ? "true" : "false");
    }
    const activeLabel = button.dataset.labelActive;
    const inactiveLabel = button.dataset.labelInactive;
    if (activeLabel !== undefined && inactiveLabel !== undefined) {
      button.textContent = isActive ? activeLabel : inactiveLabel;
    }
    const activeClass = button.dataset.activeClass;
    if (activeClass) {
      button.classList.toggle(activeClass, isActive);
    }
  };

  const initWishlistToggles = () => {
    const buttons = qsa("[data-wishlist-toggle]");
    if (!buttons.length) return;
    const csrfToken = getCsrfToken();

    const handleToggle = async (button) => {
      if (!button.dataset.url || button.dataset.loading === "true") {
        return;
      }
      button.dataset.loading = "true";
      try {
        const response = await fetch(button.dataset.url, {
          method: "POST",
          headers: {
            "X-CSRFToken": csrfToken,
            "X-Requested-With": "XMLHttpRequest",
          },
        });
        if (!response.ok) {
          throw new Error("Wishlist toggle failed");
        }
        const payload = await response.json();
        const isActive = payload.status === "added";
        updateWishlistButton(button, isActive);
        document.dispatchEvent(
          new CustomEvent("wishlist:toggled", {
            detail: {
              button,
              status: payload.status,
              added: isActive,
              payload,
            },
          }),
        );
      } catch (error) {
        button.dataset.error = "true";
        setTimeout(() => button.removeAttribute("data-error"), 2000);
      } finally {
        button.dataset.loading = "false";
      }
    };

    buttons.forEach((button) => {
      updateWishlistButton(button, button.dataset.active === "true");
      button.addEventListener("click", (event) => {
        event.preventDefault();
        handleToggle(button).catch(() => {});
      });
    });
  };

  const init = () => {
    initMobileNav();
    initAsyncSearch();
    initDismissibleToasts();
    initWishlistToggles();
  };

  return { init };
})();

window.addEventListener("DOMContentLoaded", () => matrix.init());
