//
//  PDFViewViewController.swift
//  PDFViewMock
//
//  Created by naoyuki.kan on 2023/03/21.
//

import UIKit
import PDFKit

class PDFViewViewController: UIViewController {
    private var observers = [NSKeyValueObservation]()
    private let viewModel: PDFViewViewModel
    private var pdfDocument: PDFDocument?
    let tapGestureRecognizer = UITapGestureRecognizer()
    let pdfViewGestureRecognizer = PDFViewGestureRecognizer()

    private lazy var pdfView: PDFView = {
        let pdfView = PDFView(frame: view.frame)
        pdfView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.pageShadowsEnabled = true
        pdfView.displayDirection = .vertical
        return pdfView
    }()

    private lazy var pdfThumbnailView: PDFThumbnailView = {
        let pdfThumnailView = PDFThumbnailView()
        pdfThumnailView.backgroundColor = .gray
        pdfThumnailView.layoutMode = .horizontal
        pdfThumnailView.scalesLargeContentImage = true
        pdfThumnailView.thumbnailSize = CGSize(width: 60, height: 80)
        pdfThumnailView.pdfView = pdfView
        pdfThumnailView.isHidden = true
        return pdfThumnailView
    }()

    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        let closeImage = UIImage(systemName: "xmark.circle.fill")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        return closeButton
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.tintColor = .red
        progressView.isHidden = true
        return progressView
    }()

    private lazy var pageLabel: UILabel = {
        let pageLabel = UILabel()
        pageLabel.backgroundColor = .gray
        pageLabel.textColor = .white
        pageLabel.adjustsFontSizeToFitWidth = true
        pageLabel.textAlignment = .center
        pageLabel.font = .systemFont(ofSize: 14, weight: .bold)
        return pageLabel
    }()

    init() {
        viewModel = PDFViewViewModel(viewerURL: URL(string: "https://www.apple.com/environment/pdf/Apple_Environmental_Responsibility_Report_2017.pdf")!)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .gray

        // Add subviews
        view.addSubview(pdfView)
        view.addSubview(progressView)
        view.addSubview(closeButton)
        view.addSubview(pdfThumbnailView)
        view.addSubview(pageLabel)

        setupLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged(_:)), name: .PDFViewPageChanged, object: nil)
        tapGestureRecognizer.addTarget(self, action: #selector(gestureRecognizedToggleVisibility(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        pdfView.addGestureRecognizer(pdfViewGestureRecognizer)

        // Bind this to the view model
        observers.append(viewModel.observe(\.state, options: [.initial, .new]) { [weak self] (viewModel, _) in
            guard let self = self else { return }
            print("🍻\(#function)：State is", viewModel.state.rawValue)
            switch viewModel.state {
            case .initial:
                self.progressView.isHidden = true
            case .loading:
                self.progressView.isHidden = false
            case .loaded:
                if let url = viewModel.viewerURL {
                    self.viewModel.loadPdf(url: url)
                }
            case .complete:
                    if let pdfURL = viewModel.pdfURL {
                        if let document = self.loadPDFDocument(withFileURL: pdfURL) {
                            Task { @MainActor in
                                self.pdfView.document = document
                                self.progressView.isHidden = true
                                self.pdfThumbnailView.isHidden = false
                            }
                        } else {
                            print("🍻\(#function)：Fail to load PDF", pdfURL)
                        }
                    }
            default:
                break
            }
        })

        observers.append(viewModel.observe(\.downloadProgress, options: [.new]) { [weak self] (_, change) in
            Task { @MainActor in
                guard let self = self else { return }
                if let progress = change.newValue {
                    self.progressView.progress = progress
                }
            }
        })
        viewModel.loadFeed()
    }

    private func loadPDFDocument(withFileURL url: URL) -> PDFDocument? {
        let retryCount = 3
        var retry = 0

        while pdfDocument == nil && retry < retryCount {
            pdfDocument = PDFDocument(url: url)
            retry += 1
            print("リトライ \(retry)回目")
        }

        return pdfDocument
    }

    private func setupLayout() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4.0),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -4.0),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44.0)
        ])

        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: pdfView.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])

        pdfThumbnailView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfThumbnailView.heightAnchor.constraint(equalToConstant: 100),
            pdfThumbnailView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pdfThumbnailView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pdfThumbnailView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageLabel.widthAnchor.constraint(equalToConstant: 60),
            pageLabel.centerXAnchor.constraint(equalTo: pdfView.centerXAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: pdfThumbnailView.safeAreaLayoutGuide.topAnchor)
        ])
    }

    @objc
    func pdfViewPageChanged(_ notification: Notification) {
        if pdfViewGestureRecognizer.isTracking {
            pageLabel.alpha = 0.0
            pdfThumbnailView.isHidden = true
        }
        if let currentPage = pdfView.currentPage,
           let index = pdfDocument?.index(for: currentPage),
           let pageCount = pdfDocument?.pageCount {
            if index == 0 {
                pdfView.pageBreakMargins = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
            } else {
                pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
            pageLabel.text = String(format: "%d/%d", index + 1, pageCount)
        } else {
            pageLabel.text = nil
        }
    }

    @objc
    func gestureRecognizedToggleVisibility(_ gestureRecognizer: UITapGestureRecognizer) {
        if pageLabel.alpha > 0 {
            pageLabel.alpha = 0.0
            pdfThumbnailView.isHidden = true
        } else {
            pageLabel.alpha = 1.0
            pdfThumbnailView.isHidden = false
        }
    }

    @objc
    private func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PDFViewViewController: PDFViewDelegate {
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        print("🍻\(#function)：PDF内のリンクをタップしたでい", url)

        UIApplication.shared.open(url)
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
