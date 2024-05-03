import { hbs } from "ember-cli-htmlbars";
import { apiInitializer } from "discourse/lib/api";
import RenderGlimmer from "discourse/widgets/render-glimmer";

export default apiInitializer("1.20.0", (api) => {
  api.decorateWidget("post:after", function (helper) {
    const model = helper.getModel();
    if (model.topic.archetype === "private_message") {
      return;
    }

    if (model.post_number === 1) {
      return [
        new RenderGlimmer(
          helper.widget,
          "div.topic-map__op",
          hbs`<StickyMap @outletArgs={{@data}}/>`,
          {
            model: model.topic,
            isOP: true,
          }
        ),
      ];
    }
  });
});
