/*
 * TLG Catalog pages: source-list selection, keyboard navigation and search.
 * Event delegation, so it works for every page (and pages rendered later).
 */
(function () {
  "use strict";

  function select(item) {
    var list = item.closest(".tn-tlg-list");
    if (!list) return;
    var items = list.querySelectorAll(".tn-tlg-item");
    for (var i = 0; i < items.length; i++) {
      items[i].classList.remove("active");
      items[i].setAttribute("aria-selected", "false");
    }
    item.classList.add("active");
    item.setAttribute("aria-selected", "true");
    if (window.Shiny && window.Shiny.setInputValue && list.dataset.inputId) {
      window.Shiny.setInputValue(list.dataset.inputId, item.dataset.value);
    }
  }

  function visibleItems(list) {
    return Array.prototype.filter.call(list.querySelectorAll(".tn-tlg-item"), function (el) {
      return !el.hidden && !el.closest(".tn-tlg-group[hidden]");
    });
  }

  document.addEventListener("click", function (event) {
    var item = event.target.closest && event.target.closest(".tn-tlg-item");
    if (item) select(item);
  });

  // Up/down arrows move through the list (like a navigation drawer / source list)
  document.addEventListener("keydown", function (event) {
    var item = event.target.closest && event.target.closest(".tn-tlg-item");
    if (!item || (event.key !== "ArrowDown" && event.key !== "ArrowUp")) return;
    var items = visibleItems(item.closest(".tn-tlg-list"));
    var next = items[items.indexOf(item) + (event.key === "ArrowDown" ? 1 : -1)];
    if (next) {
      event.preventDefault();
      next.focus();
      select(next);
    }
  });

  // Search: filter by id or title; hide groups without matches
  document.addEventListener("input", function (event) {
    var input = event.target;
    if (!input.classList || !input.classList.contains("tn-tlg-search")) return;
    var sidebar = input.closest(".tn-tlg-sidebar");
    var query = input.value.trim().toLowerCase();
    var groups = sidebar.querySelectorAll(".tn-tlg-group");
    for (var g = 0; g < groups.length; g++) {
      var items = groups[g].querySelectorAll(".tn-tlg-item");
      var any = false;
      for (var i = 0; i < items.length; i++) {
        var match = !query || items[i].textContent.toLowerCase().indexOf(query) !== -1;
        items[i].hidden = !match;
        any = any || match;
      }
      groups[g].hidden = !any;
    }
  });
})();
