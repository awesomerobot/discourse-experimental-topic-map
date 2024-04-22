import { apiInitializer } from "discourse/lib/api";
import StickyMap from "../components/sticky-map";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet("topic-area-bottom", StickyMap);
});
