import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service from "@ember/service";

export default class StickyMapState extends Service {
  @tracked
  stickyMapVisible = settings.topic_map_type === "static bottom" ? true : false;
  @tracked currentPost = null;

  @tracked currentTab = null;

  updateCurrentPost(post) {
    return (this.currentPost = post);
  }

  updateCurrentTab(tab) {
    if (tab === this.currentTab) {
      return (this.currentTab = null);
    }

    return (this.currentTab = tab);
  }

  @action
  toggleStickyMap() {
    if (settings.topic_map_type === "static bottom") {
      return;
    }

    this.stickyMapVisible = !this.stickyMapVisible;

    if (this.stickyMapVisible) {
      // not a long term solution
      // but moves focus for now

      const mapBtn = document.querySelector(".sticky-topic-map .btn");

      setTimeout(function () {
        mapBtn?.focus();
      }, 100);
    }
  }
}
