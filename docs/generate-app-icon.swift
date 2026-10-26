import AppKit

// Генерирует иконку приложения 1024×1024: синий градиент и белый самолёт.
// Без прозрачности (требование App Store); скругление углов делает сама iOS.
let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("context") }
let s = CGFloat(size)

// 1. Фон: диагональный градиент от светло-синего (вверху слева) к тёмно-синему (внизу справа)
let colors = [CGColor(red: 0.20, green: 0.55, blue: 1.00, alpha: 1),
              CGColor(red: 0.05, green: 0.20, blue: 0.75, alpha: 1)] as CFArray
let gradient = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

// 2. Самолёт: символ SF Symbols «airplane», окрашенный в белый
let config = NSImage.SymbolConfiguration(pointSize: 620, weight: .semibold)
let symbol = NSImage(systemSymbolName: "airplane", accessibilityDescription: nil)!.withSymbolConfiguration(config)!
let white = NSImage(size: symbol.size, flipped: false) { rect in
    symbol.draw(in: rect)
    NSColor.white.set()
    rect.fill(using: .sourceIn)
    return true
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

// Лёгкая тень под самолётом
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: CGColor(red: 0, green: 0, blue: 0.2, alpha: 0.35))

// Поворачиваем носом вверх-вправо и ставим в центр
ctx.translateBy(x: s / 2, y: s / 2)
ctx.rotate(by: CGFloat.pi / 180 * 38)
let w = white.size.width, h = white.size.height
white.draw(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
NSGraphicsContext.restoreGraphicsState()

// 3. Сохраняем PNG
let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("symbol size:", symbol.size)
