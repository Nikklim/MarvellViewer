//
//  ViewController.swift
//  MarvellViewer
//
//  Created by Dmitry on 4/23/19.
//  Copyright © 2019 Dmitry. All rights reserved.
//

import UIKit
import CoreGraphics


class ViewController: UIViewController {
    
    var dataFetcher: DataFetcher!
    weak var coordinator: MainCoordinator?
    
    @IBOutlet private var collectionView: UICollectionView!
    
    private var marvelEntities: [MarvelEntity] = Array()
    
    private var isLoading : Bool = true
    private var cellsPerRow : CGFloat = 2
    private let cellPadding : CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MarvelCharacterCollectionViewCell.register(for: collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        loadDataForFirstPage()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if UIDevice.current.userInterfaceIdiom == .pad {
            cellsPerRow = UIDevice.current.orientation.isLandscape ? 3 : 2
        } else {
            cellsPerRow = UIDevice.current.orientation.isLandscape ? 2 : 1
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func loadDataToCollection(from offset: Int, loaderView: LoaderView) {
        dataFetcher.fetch(for: offset) { [weak self] result in
            DispatchQueue.main.async {
                 self?.handleLoadedData(result: result, loaderView: loaderView)
            }
        }
    }
    
    private func handleLoadedData(result: Result<[MarvelEntity],Error>, loaderView: LoaderView) {
            switch result {
            case .success(let newEntities):
                let lastExistedItemIndex = max(self.marvelEntities.count - 1, 0)
                self.marvelEntities.append(contentsOf: newEntities)
                let indexPaths = newEntities.enumerated().map { (index, item) -> IndexPath in
                    return IndexPath(row: index + lastExistedItemIndex, section: 0)
                }
                self.collectionView.insertItems(at: indexPaths)
            case .failure(let error):
                self.handleError(error: error)
            }
            self.isLoading = false
            loaderView.removeFromSuperview()
            UIView.animate(withDuration: 1) {
                self.collectionView.contentInset = .zero
            }
        
        
    }
    
    private func loadDataForFirstPage() {
        
        let loaderView = LoaderView(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 50))
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(loaderView)
        loaderView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        loaderView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        loadDataToCollection(from: 0, loaderView: loaderView)
        
    }
    
    private func loadDataForNextPage(from offset: Int) {
        
        let loaderView = LoaderView(frame: CGRect(x: 0, y: collectionView.contentSize.height, width: collectionView.bounds.width, height: 50))
        collectionView.addSubview(loaderView)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: loaderView.frame.size.height, right: 0)
        loadDataToCollection(from: offset, loaderView: loaderView)
    }
    
}



// MARK: - MarvelCharacterCollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return marvelEntities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MarvelCharacterCollectionViewCell.reuseIdentifier, for: indexPath) as! MarvelCharacterCollectionViewCell
        cell.configure(with: marvelEntities[indexPath.row])
        return cell
    }
    
    
    
}

// MARK: - MarvelCharacterCollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        coordinator?.showDetails(for: marvelEntities[indexPath.row])
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        if offsetY > contentHeight - scrollView.frame.size.height && !isLoading {
            isLoading = true
            loadDataForNextPage(from: marvelEntities.count)
        }
    }
}



// MARK: - MarvelCharacterCollectionViewDelegateFlowLayout

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let widthMinusPadding = collectionView.bounds.width - (cellPadding + cellPadding * cellsPerRow)
        let width = widthMinusPadding / cellsPerRow
        return CGSize(width: width, height: width / 2.5)

    }
    
}
