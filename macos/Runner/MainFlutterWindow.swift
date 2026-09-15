import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    let minimumWidth: CGFloat = 1280
    let minimumHeight: CGFloat = 780

    self.contentViewController = flutterViewController
    self.setFrame(NSRect(x: 0, y: 0, width: windowFrame.width, height: windowFrame.height), display: true)
    self.center()
    self.minSize = NSSize(width: minimumWidth, height: minimumHeight)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
