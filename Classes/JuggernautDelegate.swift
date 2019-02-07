//
//  JuggernautDelegate.swift
//  Juggernaut
//

import Foundation

@objc public protocol JuggernautDelegate: class {

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didStart item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didPaused item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didResume item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didRetry item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didCancel item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didFinish item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didFail item: JuggernautItem, forItemAt indexPath: IndexPath, with error: NSError)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didUpdateProgress item: JuggernautItem, forItemAt indexPath: IndexPath)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didPopulatedInterruptedTasks items: [JuggernautItem])

	@objc optional func juggernaut(_ juggernaut: Juggernaut, notExist path: URL, forItem: JuggernautItem, at indexPath: IndexPath)
}
