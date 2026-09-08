import receive_sharing_intent

/// The iOS Share Extension (spec section 41).
///
/// It does almost nothing on purpose: it copies whatever was shared into the
/// shared app group container and hands control to the main app, which is
/// where the pipeline lives. Extensions run under a tight memory limit and are
/// killed without warning, so no analysis, no network and no model call
/// happens here.
///
/// Setup, once, in Xcode:
///   1. File > New > Target > Share Extension, named exactly "ShareExtension".
///   2. Replace the generated ShareViewController.swift with this file.
///   3. Signing & Capabilities: add App Groups to BOTH targets and use the
///      same identifier, group.<your bundle id>.
///   4. Set the extension deployment target to 15.5.
///   5. Add CUSTOM_GROUP_ID to the build settings of both targets.
class ShareViewController: RSIShareViewController {

  /// Returning false dismisses the extension immediately and opens the app.
  /// The alternative is a preview sheet the user has to dismiss, which adds a
  /// tap to the flow this whole product is built to make fast.
  override func shouldAutoRedirect() -> Bool {
    return true
  }
}
