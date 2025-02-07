import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Get the randomized background image and apply it to
    // the body element on the homepage
    const element = this.element;
    document.body.style.backgroundImage = element.style.backgroundImage;
  }
}
