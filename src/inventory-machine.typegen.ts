// This file was automatically generated. Edits will be overwritten

export interface Typegen0 {
  "@@xstate/typegen": true;
  eventsCausingActions: {
    updateItems: "done.invoke.fetch-items";
    updateItemsSize: "ITEMS.SIZE_CHANGED";
    updateSelectedItem: "ITEM.CLICKED";
  };
  internalEvents: {
    "done.invoke.fetch-items": {
      type: "done.invoke.fetch-items";
      data: unknown;
      __tip: "See the XState TS docs to learn how to strongly type this.";
    };
    "xstate.init": { type: "xstate.init" };
    "error.platform.fetch-items": {
      type: "error.platform.fetch-items";
      data: unknown;
    };
  };
  invokeSrcNameMap: {
    fetchItems: "done.invoke.fetch-items";
  };
  missingImplementations: {
    actions: never;
    services: never;
    guards: never;
    delays: never;
  };
  eventsCausingServices: {
    fetchItems: "ITEMS.RELOAD";
  };
  eventsCausingGuards: {};
  eventsCausingDelays: {};
  matchesStates: "initial" | "display" | "failed";
  tags: never;
}
