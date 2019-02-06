//
//  JuggernautDelegate.swift
//  Juggernaut
//

import Foundation

@objc public protocol JuggernautDelegate: class {

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didStart item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didPaused item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didResume item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didRetry item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didCancel item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didFinish item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didFail item: JuggernautItem, forItemAt index: Int, with error: NSError)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didUpdateProgress item: JuggernautItem, forItemAt index: Int)

	@objc optional func juggernaut(_ juggernaut: Juggernaut, didPopulatedInterruptedTasks items: [JuggernautItem])

	@objc optional func juggernaut(_ juggernaut: Juggernaut, notExist path: URL, forItem: JuggernautItem, at index: Int)
}
