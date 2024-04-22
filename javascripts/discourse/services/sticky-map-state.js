import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service from "@ember/service";

export default class StickyMapState extends Service {
  @tracked stickyMapVisible = false;
  @tracked currentPost = null;

  updateCurrentPost(post) {
    return (this.currentPost = post);
  }

  @action
  toggleStickyMap() {
    this.stickyMapVisible = !this.stickyMapVisible;

    if (this.stickyMapVisible) {
      // not a long term solution
      // but moves focus for now
      setTimeout(function () {
        document.querySelector(".sticky-topic-map .btn").focus();
      }, 100);
    }
  }
}
