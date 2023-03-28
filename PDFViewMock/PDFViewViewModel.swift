//
//  PDFViewViewModel.swift
//  PDFViewMock
//
//  Created by naoyuki.kan on 2023/03/21.
//

import Foundation

@objc
final class PDFViewViewModel: NSObject {
    @objc
    class LoadState: NSObject, RawRepresentable {
        let rawValue: String
        required init(rawValue: String) {
            self.rawValue = rawValue
        }
        static let initial: LoadState = LoadState(rawValue: "initial")
        static let loading: LoadState = LoadState(rawValue: "loading")
        static let loaded: LoadState = LoadState(rawValue: "loaded")
        static let complete: LoadState = LoadState(rawValue: "complete")
    }

    @objc
    private(set) dynamic var state: LoadState = .initial
    @objc
    private(set) dynamic var downloadProgress: Float = 0.0

    private(set) var viewerURL: URL?
    private(set) var pdfURL: URL?

    init(viewerURL: URL) {
        self.viewerURL = viewerURL
    }

    func loadFeed() {
        state = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.state = .loaded
        }
    }

    func loadPdf(url: URL) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request)
        task.resume()
    }
}

extension PDFViewViewModel: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("🍻\(#function)：Downloaded PDF at", location)
        self.pdfURL = location
        self.state = .complete
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    }

    // ダウンロードが失敗した時に呼ばれる
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("🍻\(#function): Fail to download PDF \(error)")
        }
    }
}
