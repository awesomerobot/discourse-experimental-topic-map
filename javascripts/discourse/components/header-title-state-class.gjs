import Component from "@glimmer/component";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { inject as service } from "@ember/service";

export default class HeaderTitleStateClass extends Component {
  @service stickyMapState;

  @action
  disableStickyMap() {
    if (
      this.stickyMapState.currentPost === 1 &&
      this.args.outletArgs.minimized === false
    ) {
      this.stickyMapState.stickyMapVisible = false;
    }
  }

  <template>
    <div
      {{didUpdate this.disableStickyMap this.args.outletArgs.minimized}}
    ></div>
  </template>
}
