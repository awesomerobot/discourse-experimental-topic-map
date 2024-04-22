import { apiInitializer } from "discourse/lib/api";
import StickyMapToggle from "../components/sticky-map-toggle";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet("header-topic-title-suffix", StickyMapToggle);
});
