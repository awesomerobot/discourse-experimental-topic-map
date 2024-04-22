import { apiInitializer } from "discourse/lib/api";
import HeaderTitleStateClass from "../components/header-title-state-class";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet("after-header", HeaderTitleStateClass);
});
