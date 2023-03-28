//
//  PDFViewViewController.swift
//  PDFViewMock
//
//  Created by naoyuki.kan on 2023/03/21.
//

import UIKit

class PDFViewViewController: UIViewController {
    private var observers = [NSKeyValueObservation]()
    private let viewModel: PDFViewViewModel
    private var pdfViewer: PDFViewer?

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
        pdfViewer = PDFViewer(frame: view.frame)
        guard let pdfViewer = pdfViewer else { return }

        // Add subviews
        view.addSubview(pdfViewer)
        view.addSubview(progressView)
        view.addSubview(closeButton)

        setupLayout()

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
                    Task { @MainActor in
                        self.progressView.isHidden = true
                    }
                    pdfViewer.setPDFwithDownloadURL(url: pdfURL)
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

    private func setupLayout() {
        guard let pdfViewer = pdfViewer else { return }
        pdfViewer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfViewer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfViewer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pdfViewer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pdfViewer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
            progressView.topAnchor.constraint(equalTo: pdfViewer.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: pdfViewer.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: pdfViewer.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])
    }

    @objc
    private func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
