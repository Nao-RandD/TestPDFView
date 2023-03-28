//
//  PDFViewer.swift
//  PDFViewMock
//
//  Created by naoyuki.kan on 2023/03/28.
//

import UIKit
import PDFKit

protocol PDFViewerDelegate: NSObject {
    func clickPDFLink(url: URL)
}

final class PDFViewer: UIView {
    private var pdfDocument: PDFDocument?
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let pdfViewGestureRecognizer = PDFViewGestureRecognizer()

    private(set) lazy var pdfView: PDFView = {
        let pdfView = PDFView(frame: frame)
        pdfView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }()

    private(set) lazy var pdfThumbnailView: PDFThumbnailView = {
        let pdfThumnailView = PDFThumbnailView()
        pdfThumnailView.backgroundColor = .gray
        pdfThumnailView.layoutMode = .horizontal
        pdfThumnailView.scalesLargeContentImage = true
        pdfThumnailView.thumbnailSize = CGSize(width: 60, height: 80)
        pdfThumnailView.pdfView = pdfView
        pdfThumnailView.isHidden = true
        return pdfThumnailView
    }()

    private lazy var pageLabel: UILabel = {
        let pageLabel = UILabel()
        pageLabel.backgroundColor = .gray
        pageLabel.textColor = .white
        pageLabel.adjustsFontSizeToFitWidth = true
        pageLabel.textAlignment = .center
        pageLabel.font = .systemFont(ofSize: 14, weight: .bold)
        pageLabel.isHidden = true
        return pageLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPDFwithDownloadURL(url: URL) {
        if let document = PDFDocument(url: url) {
            self.pdfDocument = document
            Task { @MainActor in
                self.pdfView.document = document
                self.pdfView.displayDirection = .vertical
                self.pdfThumbnailView.isHidden = false
                self.pageLabel.isHidden = false
                self.pageLabel.textColor = .white
            }
        } else {
            print("Fail to load PDF file in PDFViewer")
        }
    }

    private func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged(_:)), name: .PDFViewPageChanged, object: nil)

        tapGestureRecognizer.addTarget(self, action: #selector(gestureRecognizedToggleVisibility(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        pdfView.addGestureRecognizer(pdfViewGestureRecognizer)

        addSubview(pdfView)
        addSubview(pdfThumbnailView)
        addSubview(pageLabel)

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        pdfThumbnailView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfThumbnailView.heightAnchor.constraint(equalToConstant: 100),
            pdfThumbnailView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            pdfThumbnailView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            pdfThumbnailView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageLabel.heightAnchor.constraint(equalToConstant: 40),
            pageLabel.widthAnchor.constraint(equalToConstant: 60),
            pageLabel.centerXAnchor.constraint(equalTo: pdfView.centerXAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: pdfThumbnailView.safeAreaLayoutGuide.topAnchor)
        ])
    }

    @objc
    func pdfViewPageChanged(_ notification: Notification) {
        if pdfViewGestureRecognizer.isTracking {
            pageLabel.isHidden = true
            pdfThumbnailView.isHidden = true
        }
        if let currentPage = pdfView.currentPage,
           let index = pdfDocument?.index(for: currentPage),
           let pageCount = pdfDocument?.pageCount {
            pageLabel.text = String(format: "%d/%d", index + 1, pageCount)
        } else {
            pageLabel.text = nil
        }
    }

    @objc
    func gestureRecognizedToggleVisibility(_ gestureRecognizer: UITapGestureRecognizer) {
        if !pageLabel.isHidden {
            pageLabel.isHidden = true
            pdfThumbnailView.isHidden = true
        } else {
            pageLabel.isHidden = false
            pdfThumbnailView.isHidden = false
        }
    }
}

class PDFViewGestureRecognizer: UIGestureRecognizer {
    var isTracking = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }
}
