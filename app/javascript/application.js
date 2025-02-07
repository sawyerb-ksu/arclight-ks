// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "controllers"

// The following did NOT get added by the arclight generator, but it appears to be needed
import bootstrap from "bootstrap"
window.bootstrap = bootstrap

import "@github/auto-complete-element"

// This seems odd but see: https://github.com/projectblacklight/arclight/issues/1401
import Blacklight from "blacklight"
window.Blacklight = Blacklight

import Truncate from 'arclight/truncate_controller'
Stimulus.register('arclight-truncate', Truncate)

import dialogPolyfill from "dialog-polyfill"
Blacklight.onLoad(() => {
  const dialog = document.querySelector('dialog')
  dialogPolyfill.registerDialog(dialog)
})

import "arclight"

// Adapted from blacklight-hierarchy generator, see:
// https://github.com/sul-dlss/blacklight-hierarchy/blob/main/lib/generators/blacklight_hierarchy/templates/blacklight_hierarchy.js
import BlacklightHierarchyController from 'blacklight/hierarchy/blacklight_hierarchy_controller'
import { Application } from '@hotwired/stimulus'
const application = Application.start()
application.register("b-h-collapsible", BlacklightHierarchyController)

Blacklight.onLoad(() => {
  // Initialize Bootstrap tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
})

import BlacklightRangeLimit from "blacklight-range-limit";
BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad });
