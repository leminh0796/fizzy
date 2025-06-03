import { Controller } from "@hotwired/stimulus"
import { nextFrame } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = [ "item" ]
  static values = {
    reverseOrder: { type: Boolean, default: false },
    selectionAttribute: { type: String, default: "aria-selected" },
    focusOnSelection: { type: Boolean, default: true },
    actionableItems: { type: Boolean, default: false }
  }

  connect() {
    this.reset()
  }

  // Actions

  reset(event) {
    if (this.reverseOrderValue) {
      this.selectLast()
    } else {
      this.selectFirst()
    }
  }

  navigate(event) {
    this.#keyHandlers[event.key]?.call(this, event)
  }

  select({ target }) {
    this.#setCurrentFrom(target)
  }

  selectCurrentOrReset(event) {
    if (this.currentItem) {
      this.#setCurrentFrom(this.currentItem)
    } else {
      this.reset()
    }
  }

  selectFirst() {
    this.#setCurrentFrom(this.#visibleItems[0])
  }

  selectLast() {
    this.#setCurrentFrom(this.#visibleItems[this.#visibleItems.length - 1])
  }

  // Private

  get #visibleItems() {
    return this.itemTargets.filter(item => !item.hidden)
  }

  #selectPrevious() {
    const index = this.#visibleItems.indexOf(this.currentItem)
    if (index > 0) {
      this.#setCurrentFrom(this.#visibleItems[index - 1])
    }
  }

  #selectNext() {
    const index = this.#visibleItems.indexOf(this.currentItem)
    if (index >= 0 && index < this.#visibleItems.length - 1) {
      this.#setCurrentFrom(this.#visibleItems[index + 1])
    }
  }

  async #setCurrentFrom(element) {
    const selectedItem = this.#visibleItems.find(item => item.contains(element))

    if (selectedItem) {
      this.#clearSelection()
      selectedItem.setAttribute(this.selectionAttributeValue, "true")
      this.currentItem = selectedItem
      await nextFrame()
      if (this.focusOnSelectionValue) { this.currentItem.focus() }
    }
  }

  #clearSelection() {
    for (const item of this.itemTargets) {
      item.removeAttribute(this.selectionAttributeValue)
    }
  }

  #handleArrowKey(event, fn) {
    if (event.shiftKey || event.metaKey || event.ctrlKey) { return }
    fn.call()
    event.preventDefault()
  }

  #clickCurrentItem(event) {
    if (this.actionableItemsValue && this.currentItem && this.#visibleItems.length) {
      const clickableElement = this.currentItem.querySelector("a,button") || this.currentItem
      clickableElement.click()
      event.preventDefault()
    }
  }

  #toggleCurrentItem(event) {
    if (this.actionableItemsValue && this.currentItem && this.#visibleItems.length) {
      const toggleable = this.currentItem.querySelector("input[type=checkbox]")
      if (toggleable) {
        toggleable.checked = !toggleable.checked
        toggleable.dispatchEvent(new Event('change', { bubbles: true }))
        event.preventDefault()
      }
    }
  }

  #keyHandlers = {
    ArrowDown(event) {
      this.#handleArrowKey(event, this.#selectNext.bind(this))
    },
    ArrowUp(event) {
      this.#handleArrowKey(event, this.#selectPrevious.bind(this))
    },
    ArrowRight(event) {
      this.#handleArrowKey(event, this.#selectNext.bind(this))
    },
    ArrowLeft(event) {
      this.#handleArrowKey(event, this.#selectPrevious.bind(this))
    },
    Enter(event) {
      if (event.ctrlKey || event.metaKey) {
        this.#toggleCurrentItem(event)
      } else {
        this.#clickCurrentItem(event)
      }
    }
  }
}
