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

        API.PetFinder.Routes.GetAnimals(animalType: .bird).request { result in
            switch result {
                case .success(let birds):
                    print(birds)
                case .failure(let error):
                    print(error)
            }
        }

        //ViewDidLoad isnt an async function so all async operations need to be wrapped in a Task
        Task {
            switch await API.PetFinder.Routes.GetAnimals(animalType: .dog).task.result {
                case .success(let dogs):
                    print(dogs)
                case .failure(let error):
                    print(error)
            }
        }

        Task {
            let dogs = try await API.PetFinder.Routes.GetAnimals(animalType: .dog).task.value
            print(dogs)
        }

        Task {
            async let cats = API.PetFinder.Routes.GetAnimals(animalType: .cat).result
            async let dogs = API.PetFinder.Routes.GetAnimals(animalType: .dog).result
            async let birds = API.PetFinder.Routes.GetAnimals(animalType: .bird).result
            let allAnimals = await [cats, dogs, birds] //This runs all 3 requests in parallel
            print(allAnimals)
        }

        //Combine example
        API.PetFinder.Routes.GetAnimals(animalType: .cat).publisher
            .combineLatest(API.PetFinder.Routes.GetAnimals(animalType: .dog).publisher,
                           API.PetFinder.Routes.GetAnimals(animalType: .bird).publisher)
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
