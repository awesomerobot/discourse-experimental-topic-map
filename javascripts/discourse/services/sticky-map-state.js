import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service from "@ember/service";

export default class StickyMapState extends Service {
  @tracked
  stickyMapVisible = settings.topic_map_type === "static bottom" ? true : false;
  @tracked currentPost = null;

  updateCurrentPost(post) {
    return (this.currentPost = post);
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
