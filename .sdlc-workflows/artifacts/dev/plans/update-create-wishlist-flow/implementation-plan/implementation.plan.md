Revise CreateWishlist page 2 add product UI

# Requirement Context

## Current State

`CreateWishlistPage2` renders wishlist items as `WishlistItemCard` views inside a `List`, using a horizontal (`HStack`) layout with text fields on the left and an `ImagePickerBox` on the right. Images in selected state use `.scaledToFill()` and `.clipped()` but lack a fixed explicit frame, resulting in inconsistent cropping across items. The keyboard toolbar "Done" button exists but is bound only to the description field's single `@FocusState var isInputActive: Bool`, leaving the name and item link fields without a dismiss action. The item list header and "add new item" control are plain text with no visual polish.

## Goals

- Redesign `WishlistItemCard` with a vertical product card layout (image-first) that matches a modern wishlist creation app aesthetic
- Enforce a fixed, uniform image frame with `scaledToFill` and `clipShape` so all images crop consistently regardless of source aspect ratio
- Wire the keyboard toolbar "Done" button to all three text field focus states so it always dismisses the keyboard
- Improve the visual polish of the "Add new item" control

## Risk & Mitigation

- **Risk**: Removing `GeometryReader` and the `height` parameter may affect layout in edge-case screen sizes. **Mitigation**: Use a fixed `minHeight: 180` for the image area which works reliably across iPhone sizes.
- **Risk**: Multiple `WishlistItemCard` instances each declaring a `.toolbar` may cause keyboard toolbar duplication. **Mitigation**: SwiftUI correctly scopes toolbar items per focused view, so each card's toolbar is only active when that card has focus—this is the same pattern used in `CreateWishlistPage1`.

# Technical Specification Context

## Functional Requirements:

- System MUST render all item images at a fixed frame (`maxWidth: .infinity`, `minHeight: 180`) using `.scaledToFill()`, `.clipped()`, and `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`
- System MUST display an upload placeholder when no image is selected, centered with `Image("upload")` icon and an "Add photo" label
- System MUST provide a keyboard toolbar "Done" button that sets `focusedField = nil`, dismissing all three text field focus states (name, description, itemLink)
- System MUST retain three input fields bound to `WishlistItem`: item `name`, `description`, and `itemLink`
- System MUST NOT add a price field
- System MUST retain the ability to add new items (appending `WishlistItem()`) and delete items via `.onDelete`
- System MUST replace the plain `Text("+ add new item")` with a visually styled add-item row

## Non-Functional Requirements:

- System MUST use project color tokens (`.wishiePink`, `.lightYellow1`, `.white`) and `WishieFont` typographic styles from `Wishie/Resources/WishieCustomFont.swift`
- System MUST follow SwiftUI composition patterns from `knowledge.coding.md`: state owned in view models, UI bindings via `@Binding`, focus state per view instance
- System MUST maintain full backward compatibility with `WishlistItem` model (`Wishie/Models/WishlistItem.swift`) and `CreateWishlistViewModel` (`Wishie/Screens/CreateList/CreateWishlistViewModel.swift`)
