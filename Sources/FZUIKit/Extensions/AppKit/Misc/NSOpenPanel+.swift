//
//  NSOpenPanel+.swift
//
//
//  Created by Florian Zand on 11.02.24.
//

#if os(macOS)
import AppKit
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

extension NSOpenPanel {
    /// Sets the Boolean that indicates whether the user can choose directories in the panel.
    @discardableResult
    @objc open func canChooseDirectories(_ canChoose: Bool) -> Self {
        self.canChooseDirectories = canChoose
        return self
    }
    
    /// Sets the Boolean that indicates whether the user can choose files in the panel.
    @discardableResult
    @objc open func canChooseFiles(_ canChoose: Bool) -> Self {
        self.canChooseFiles = canChoose
        return self
    }
    
    /// Sets the Boolean that indicates whether the panel resolves aliases.
    @discardableResult
    @objc open func resolvesAliases(_ resolves: Bool) -> Self {
        self.resolvesAliases = resolves
        return self
    }
    
    /// Sets the Boolean value that indicates how the panel responds to iCloud documents that aren't fully downloaded locally.
    @discardableResult
    @objc open func isAccessoryViewDisclosed(_ isDisclosed: Bool) -> Self {
        self.isAccessoryViewDisclosed = isDisclosed
        return self
    }
            
    /// Sets the Boolean that indicates whether the user may select multiple files and directories.
    @discardableResult
    @objc open func allowsMultipleSelection(_ allows: Bool) -> Self {
        self.allowsMultipleSelection = allows
        return self
    }
    
    /// Sets the Boolean that indicates whether the user may select multiple files and directories.
    @discardableResult
    @objc open func canDownloadUbiquitousContents(_ canDownload: Bool) -> Self {
        self.canDownloadUbiquitousContents = canDownload
        return self
    }
    
    /// Sets the Boolean value that indicates how the panel responds to iCloud documents that have conflicting versions.
    @discardableResult
    @objc open func canResolveUbiquitousConflicts(_ canResolve: Bool) -> Self {
        self.canResolveUbiquitousConflicts = canResolve
        return self
    }
        
    /// Sets the current directory shown in the panel.
    @discardableResult
    @objc open func directoryURL(_ directoryURL: URL?) -> Self {
        self.directoryURL = directoryURL
        return self
    }
    
    /**
     Creates a panel for selecting files of the specified content types.
     
     - Parameters:
        - allowedContentTypes: The allowed file content types. To allow selecting directories, include `directory`.
        - allowsMultiple: A Boolean value that indicates whether the user may select multiple files and directories.
        - message: The message of the panel.
        - openButton: The title of the open button. The default value is `nil`, which uses `open` as title.
        - directory: The current directory of the panel.
     
     - Returns: The panel for selecting files.
     */
    @available(macOS 11.0, *)
    convenience init(_ allowedContentTypes: [UTType], allowsMultiple: Bool, message: String? = nil, openButton: String? = nil, directory: URL? = nil) {
        self.init()
        self.allowedContentTypes = allowedContentTypes
        self.message = message
        self.prompt = openButton
        self.canChooseDirectories = allowedContentTypes.contains(.directory)
        self.allowsMultipleSelection = allowsMultiple
        self.directoryURL = directory
    }
        
    /**
     Opens a panel for selecting files of the specified content types.
     
     - Parameters:
        - allowedContentTypes: The allowed file content types. To allow selecting directories, include `directory`.
        - allowsMultiple: A Boolean value that indicates whether the user may select multiple files and directories.
        - message: The message of the panel.
        - openButton: The title of the open button. The default value is `nil`, which uses `open` as title.
        - directory: The current directory of the panel.
        - completionHandler: The completion handler which returns the response.
     
     - Returns: The panel for selecting files.
     */
    @available(macOS 11.0, *)
    @discardableResult
    public static func openFiles(_ allowedContentTypes: [UTType], allowsMultiple: Bool, message: String? = nil, openButton: String? = nil, directory: URL? = nil, completionHandler: @escaping (_ response: Response)->()) -> NSOpenPanel {
        let openPanel = NSOpenPanel(allowedContentTypes, allowsMultiple: allowsMultiple, message: message, openButton: openButton, directory: directory)
        openPanel.begin { response in
            completionHandler(Response(response, openPanel.urls))
        }
        return openPanel
    }
    
    /**
     Opens a window sheet panel for selecting files of the specified content types.
     
     - Parameters:
        - allowedContentTypes: The allowed file content types. To allow selecting directories, include `directory`.
        - allowsMultiple: A Boolean value that indicates whether the user may select multiple files and directories.
        - message: The message of the panel.
        - openButton: The title of the open button. The default value is `nil`, which uses `open` as title.
        - directory: The current directory of the panel.
        - window: The window that presents the file selection panel.
        - completionHandler: The completion handler which returns the response.
     
     - Returns: The panel for selecting files.
     */
    @available(macOS 11.0, *)
    @discardableResult
    public static func openFilesSheet(_ allowedContentTypes: [UTType], allowsMultiple: Bool, message: String? = nil, openButton: String? = nil, directory: URL? = nil, window: NSWindow, completionHandler: @escaping (_ response: Response)->()) -> NSOpenPanel {
        let openPanel = NSOpenPanel(allowedContentTypes, allowsMultiple: allowsMultiple, message: message, openButton: openButton, directory: directory)
        openPanel.beginSheet(window) { response in
            completionHandler(Response(response, openPanel.urls))
        }
        return openPanel
    }
    
    /// The response of an open panel
    public enum Response {
        /// The selected urls.
        case urls([URL])
        /// The panel has been canceled.
        case cancel
        /// The panel has been stopped.
        case stop
        
        init(_ response: NSApplication.ModalResponse, _ urls: [URL]) {
            switch response {
            case .OK: self = .urls(urls)
            case .cancel: self = .cancel
            default: self = .stop
            }
        }
    }
}
#endif
