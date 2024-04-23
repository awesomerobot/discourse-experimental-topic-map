import { apiInitializer } from "discourse/lib/api";
import StickyMapToggle from "../components/sticky-map-toggle";

export default apiInitializer("1.14.0", (api) => {
  if (settings.topic_map_type === "sticky top") {
    api.renderInOutlet("header-topic-title-suffix", StickyMapToggle);
  } else if (settings.topic_map_type === "sticky bottom") {
    api.renderInOutlet("timeline-footer-controls-after", StickyMapToggle);
  }
});
