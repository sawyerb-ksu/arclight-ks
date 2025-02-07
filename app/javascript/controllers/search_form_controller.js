import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('submit', this.handleSubmit.bind(this));

    // Since we render the search form twice on the page (once in the header and
    // again in the Advanced modal), we have to ensure the IDs are unique. So we
    // tack _advanced on as a suffix to elements that have ids. This
    // especially is important for a11y.

    if (this.element.closest('#advanced-modal')) {
      this.element.querySelectorAll('input[id], select[id], button[id]').forEach((element) => {
        element.id = `${element.id}_advanced`;
      });
      this.element.querySelectorAll('[for]').forEach((element) => {
        const currentForValue = element.getAttribute('for');
        element.setAttribute('for', currentForValue + '_advanced');
      });
    }
  }

  handleSubmit(event) {
    event.preventDefault();

    const selectElement = this.element.querySelector('[id^="within_collection"]');
    const hiddenGroupByCollection = this.element.querySelector('input[name="group"]');

    // If the search was *within* a collection, we don't want
    // the results grouped by collection
    if (selectElement.value) {
      hiddenGroupByCollection?.remove();
    }

    this.element.submit();
  }
}
