//
//  ViewController.swift
//  dprakhovPW1
//
//  Created by Данил Прахов on 14.09.2025.
//

import UIKit

final class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private var colorViews: [UIView]!      // Все прямоугольники с моего сториборда
    @IBOutlet private weak var changeButton: UIButton! // Кнопка "Click It!"

    // MARK: - Properties
    private var updateTimer: Timer?                  // Таймер для "удержания" кнопки

    // MARK: - Config (дабы не было никаких "магических чисел", согласно пункту 9)
    private let animationDuration: TimeInterval = 0.35
    private let cornerRadiusRange: ClosedRange<CGFloat> = 0...22
    private let timerInterval: TimeInterval = 0.5

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Скругления рисуем корректно (обрезаем содержимое по радиусу)
        colorViews.forEach { $0.layer.masksToBounds = true }

        setupLabelsInViews() // Вставляем подписи внутрь блоков

        // Навешиваем события на кнопку: начало её удержки и отпуск
        changeButton.addTarget(self, action: #selector(holdDown), for: .touchDown)
        changeButton.addTarget(self, action: #selector(holdRelease), for: [.touchUpInside, .touchUpOutside])

        // Делаем стартовую уникальную "раскраску" вьюшек
        apply(colors: makeUniqueRandomColors(count: colorViews.count))
    }

    // MARK: - Текст внутри цветных вьюшек
    /// Кладём UILabel в каждый прямоугольник и растягиваем по краям с отступом
    private func setupLabelsInViews() {
        for view in colorViews {
            let label = UILabel()
            label.text = "IOS ЭТО ОЧ КРУТО!"
            label.font = .systemFont(ofSize: 96, weight: .heavy)     // Большой толстый шрифт
            label.textColor = UIColor.white.withAlphaComponent(0.6)  // Белый с небольшой прозрачностью
            label.textAlignment = .center
            label.numberOfLines = 0
            label.adjustsFontSizeToFitWidth = true    // Уменьшаем шрифт, в случае если не лезет
            label.minimumScaleFactor = 0.1

            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
            ])
        }
    }

    // MARK: - Actions (удержание кнопки)
    /// Нажали и держим — запускаем одно обновление и пускаем таймер
    @objc private func holdDown() {
        updateColors()
        updateTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            self?.updateColors()
        }
    }

    /// Отпустили — останавливаем таймер
    @objc private func holdRelease() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    /// Обновляем цвета/радиусы с анимацией и запускаем эмодзи в движение
    private func updateColors() {
        changeButton.isEnabled = false
        let newColors = makeUniqueRandomColors(count: colorViews.count)

        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            self?.apply(colors: newColors)
        }, completion: { [weak self] _ in
            // В случае отсутствия таймера - снова разрешаем клик по кнопке
            if self?.updateTimer == nil {
                self?.changeButton.isEnabled = true
            }
        })

        runEmojiAnimation()
    }

    // MARK: - UI Updates
    /// Применяем цвета и случайный cornerRadius ко всем вьюшкам
    private func apply(colors: [UIColor]) {
        guard colors.count == colorViews.count else { return }
        for (view, color) in zip(colorViews, colors) {
            view.backgroundColor = color
            view.layer.cornerRadius = CGFloat.random(in: cornerRadiusRange)
        }
    }

    // MARK: - Уникальные случайные цвета в HEX
    private func makeUniqueRandomColors(count: Int) -> [UIColor] {
        var seenColors = Set<String>()     // тут храним уже использованные HEX
        var resultColor: [UIColor] = []
        while resultColor.count < count {
            let hex = UIColor.randomHex()
            if !seenColors.contains(hex), let c = UIColor(hex: hex) {
                seenColors.insert(hex); resultColor.append(c)
            }
        }
        return resultColor
    }

    // MARK: - Анимация: пролёт эмодзи между блоками
    private func runEmojiAnimation() {
        guard colorViews.count > 1 else { return }

        // Пускаем в сдвиг 3 эмодзи по условным «коридорчикам» между блоками вьюшек
        let emojis = ["📱", "👨‍💻", "🚀"]

        // Считаем Y-позиции центров промежутков
        var yPositions: [CGFloat] = []
        for i in 0..<(colorViews.count - 1) {
            let topView = colorViews[i]
            let bottomView = colorViews[i + 1]
            let y = (topView.frame.maxY + bottomView.frame.minY) / 2
            yPositions.append(y)
        }

        // Запускаем сами анимации
        for (index, emoji) in emojis.enumerated() {
            let label = UILabel()
            label.text = emoji
            label.font = .systemFont(ofSize: 50)
            label.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            view.addSubview(label)

            let y = yPositions[index % yPositions.count]
            let fromLeft = index % 2 == 0
            let startX = fromLeft ? -label.frame.width : view.bounds.width
            let endX = fromLeft ? view.bounds.width : -label.frame.width
            label.center = CGPoint(x: startX, y: y)

            UIView.animate(withDuration: 1.0, delay: Double(index) * 0.2, options: [.curveEaseInOut], animations: {
                label.center.x = endX
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }
}

// MARK: - UIColor <-> HEX (sRGB)
private extension UIColor {
    /// Парсим строку "RRGGBB" или "#RRGGBB" и создаём цвет в sRGB
    convenience init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                         .replacingOccurrences(of: "#", with: "")
                         .uppercased()
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8)  & 0xFF) / 255
        let b = CGFloat( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    /// Просто генерим случайный HEX вида "A1B2C3"
    static func randomHex() -> String {
        String(format: "%06X", UInt32.random(in: 0...0xFFFFFF))
    }
}
