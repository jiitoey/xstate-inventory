import { assign, createMachine } from "xstate";

interface Item {
  contractAddress: string;
  tokenId: number;
  name: string;
  description: string;
  image: string;
}

interface Context {
  itemsSize: string;
  totalItems: number;
  items: Item[];
  selectedItem: Item;
}

const mockFetchItemsResult = async () => {
  const totalItems = 10;
  const nList = [...Array(10).keys()];
  const mockedItems = [
    {
      contractAddress: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d",
      tokenId: 1,
      name: "Silver",
      description: "This is a silver box",
      image: "https://picsum.photos/64",
    },
    {
      contractAddress: "0x2d677Dbe16752A066ef83e382DcC04D7003A61Ed ",
      tokenId: 1,
      name: "Gold",
      description: "This is a gold box",
      image: "https://picsum.photos/64",
    },
    {
      contractAddress: "0xcdd02E7849CBBfeaF6401cfDc434999ff5fC0f04",
      tokenId: 1,
      name: "Platinum",
      description: "This is a platinum box",
      image: "https://picsum.photos/64",
    },
  ];
  const items = nList.map((n) => {
    const randomMockedItem =
      mockedItems[Math.floor(Math.random() * mockedItems.length)];
    return { ...randomMockedItem, image: randomMockedItem.image + `?${n}` };
  });
  if (Math.floor(Math.random() * 100) < 10) throw "Forced fetch items ERROR";
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({ totalItems, items });
    }, 500);
  }) as Promise<{
    totalItems: number;
    items: Item[];
  }>;
};

export const itemsMachine = createMachine(
  {
    tsTypes: {} as import("./inventory-machine.typegen").Typegen0,
    id: "ITEMS",
    schema: {
      context: {} as Context,
      events: {} as
        | { type: "ITEMS.SIZE_CHANGED"; itemsSize: string }
        | { type: "ITEMS.RELOAD" }
        | { type: "ITEM.CLICKED"; selectedItem: number },
      services: {} as {
        fetchItems: {
          data: {
            totalItems: number;
            items: Item[];
          };
        };
      },
    },
    context: {
      itemsSize: "small",
      totalItems: 0,
      items: [],
      selectedItem: null,
    },
    states: {
      initial: {
        invoke: {
          id: "fetch-items",
          src: "fetchItems",
          onDone: {
            target: "display",
            actions: "updateItems",
          },
          onError: { target: "failed" },
        },
      },
      display: {
        on: {
          "ITEMS.SIZE_CHANGED": {
            actions: "updateItemsSize",
          },
          "ITEM.CLICKED": {
            actions: "updateSelectedItem",
          },
        },
      },
      failed: {
        on: {
          "ITEMS.RELOAD": {
            target: "initial",
          },
        },
      },
    },
    initial: "initial",
  },
  {
    services: {
      fetchItems: async (context) => {
        // const response = await fetch(
        //   `https://www.bgf.com/?sortby=${context.sortBy}&skip=${skip}&limit=${limit}`
        // );
        // const json = await response.json();
        const json = await mockFetchItemsResult();
        console.log("json", json);
        return json;
      },
    },
    actions: {
      updateItems: assign((context, event) => {
        return {
          ...context,
          items: event.data.items,
          totalItems: event.data.totalItems,
          selectedItem:
            event.data.items.length > 0 ? event.data.items[0] : null,
        };
      }),
      updateItemsSize: assign((context, event) => {
        return {
          ...context,
          itemsSize: event.itemsSize,
        };
      }),
      updateSelectedItem: assign((context, event) => {
        return {
          ...context,
          selectedItem: context.items[event.selectedItem],
        };
      }),
    },
  }
);
