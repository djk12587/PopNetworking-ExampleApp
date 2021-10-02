//
//  ViewController.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import UIKit
import Combine

class ViewController: UIViewController {

    private var tokens: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        API.Jokes.Routes.GetJoke().request { result in
            switch result {
                case .success(let joke):
                    print(joke)
                case .failure(let error):
                    print(error)
            }
        }

        API.Jokes.Routes.GetTenJokes().request { result in
            switch result {
                case .success(let jokes):
                    print(jokes)
                case .failure(let error):
                    print(error)
            }
        }

        API.PetFinder.Routes.GetAnimals(animalType: .bird).request { result in
            switch result {
                case .success(let birds):
                    print(birds)
                case .failure(let error):
                    print(error)
            }
        }

        //Combine example
        API.PetFinder.Routes.GetAnimals(animalType: .dog).future
            .combineLatest(API.PetFinder.Routes.GetAnimals(animalType: .bird).future,
                           API.PetFinder.Routes.GetAnimals(animalType: .cat).future)
            .sink { result in
                print(result) //prints out the result for all dogs, birds and cats
            }
            .store(in: &tokens)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "Nothing to see here. \n\nCheckout ViewController.swift to see PopNetworking in action."
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
}
