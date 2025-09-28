import { Controller } from "@hotwired/stimulus"
import { nextFrame } from "helpers/timing_helpers";

export default class extends Controller {
  static targets = [ "clickable" ]

  async click() {
    await nextFrame()
    this.clickableTarget.click()
  }
}
