import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service from "@ember/service";

export default class StickyMapState extends Service {
  @tracked stickyMap = true;

  @action
  toggleStickyMap() {
    this.stickyMap = !this.stickyMap;
  }
}
