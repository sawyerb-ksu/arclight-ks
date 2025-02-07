// DUL custom copy of https://github.com/sul-dlss/blacklight-hierarchy/blob/main/app/assets/javascripts/blacklight/hierarchy/blacklight_hierarchy_controller.js

// This fixes a blacklight-hierarchy BS5 incompatibility (as of 6.1.2) where the facet
// selection removal "X" text lacks the new visually-hidden class.
//
// ...and fixes a bug where if you click on a nested facet value to get to a results page,
// the selected hierarchical facet values are not expanded on that page.
//
// As far as I can tell, this Stimulus controller supplants the hierarchy.js file in the
// gem (which depends on jQuery), so we are now able to use the gem without jQuery.

import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "list" ]
  connect() {
    this.element.classList.add("twiddle");

    this.element.querySelectorAll('.sr-only').forEach((element) => {
      element.classList.add("visually-hidden");
    });

    // DUL CUSTOMIZATION here -- check if a descendant is selected:
    const hasDescendantWithClass = this.element.querySelector(':scope .selected') !== null;

    if (hasDescendantWithClass) {
      this.element.classList.add("twiddle-open");
      this.element.querySelector(':scope .collapse').classList.add("in", "show");
    }
  }

  toggle() {
    this.element.classList.toggle("twiddle-open");
  }
}
