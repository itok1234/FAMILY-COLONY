# Rendered Visual QA — follow-up findings (2026-11-26)

## Result
Visual QA remains **FAIL / BLOCKED**. The captured screenshot (workflow artifact inspected) shows a real 3D scene, but two unresolved visual defects:
- A large opaque blue rectangle overlays the upper-left/center roadway and scenery. It is blank in the captured frame.
- Two blank golden rectangular panels float at mid-right, obstructing scene visibility.

## Source investigation
- The screenshot's large blue rectangle does not match the chat backing's size/color conclusively; the chat backing is only instantiated hidden and toggled by explicit chat actions. No source has been proven to own the screenshot rectangle.
- The interaction controller creates a dark-blue contextual menu backing and hides it initially; it is not proven to match either overlay.
- The world controller creates a spatial Android session-verification gate (large dark backing and gold return button), but this is Android-specific and does not conclusively explain the desktop visual capture.
- The environment builder explicitly describes scalable placeholder meshes; however the two gold rectangles have not been traced to specific nodes, so deleting or hiding guessed nodes would risk legitimate scenery/gameplay.

## Required next diagnostic
Add source-node identification to the rendered QA capture path (node names, mesh/material bounds and visibility for candidate UI/panel nodes) and capture a second view with a camera/scene tree snapshot. Only after the offending nodes are positively identified should a minimal source-level correction be made.

## No false PASS
The capture is evidence of render output, not a QA pass. No overlay defect is marked fixed in this report.
