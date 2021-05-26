//
//  ViewController.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        API.Jokes.Routes.GetJoke(overrideResult: true).request { result in
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

        API.Jokes.Routes.GetJoke(overrideResult: false).and(run: API.Jokes.Routes.GetJoke(overrideResult: false)) { aggregatedResult in
            switch aggregatedResult {
                case .success(let twoJokes):
                    print(twoJokes)
                case .failure(let error):
                    print(error)
            }
        }

        API.PetFinder.Routes.GetAnimals(animalType: .dog).andThen(run: API.PetFinder.Routes.GetRandomAnimal.self) { randomAnimalResult in
            switch randomAnimalResult {
                case .success(let randomAnimal):
                    print(randomAnimal)
                case .failure(let error):
                    print(error)
            }
        }
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
