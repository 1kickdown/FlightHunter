//
//  AboutView.swift
//  FlightHunter
//
//  Экран «О приложении»: как работает сервис, где покупаются билеты, ссылки
//  и кнопка удаления всех данных пользователя.
//

import SwiftUI
import SwiftData

struct AboutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingDelete = false
    @State private var isDeleting = false
    @State private var errorText: String?
    @State private var didDelete = false

    // "1.0 (1)": версия и номер сборки
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Версия", value: versionText)
                }

                Section("Как это работает") {
                    Text("Мы следим за ценами на авиабилеты по вашим направлениям и сообщаем, когда они падают. Цены ориентировочные: они берутся из недавних поисков пользователей Aviasales и могут отличаться от актуальных.")
                    Text("Мы не продаём билеты. Кнопка «Купить» открывает поиск на сайте Aviasales по партнёрской ссылке, там же происходит оплата. За покупки по этим ссылкам мы можем получать комиссию, цена для вас от этого не меняется.")
                }

                if AppLinks.privacyPolicyURL != nil || AppLinks.supportURL != nil {
                    Section("Ссылки") {
                        if let url = AppLinks.privacyPolicyURL {
                            Link("Политика конфиденциальности", destination: url)
                        }
                        if let url = AppLinks.supportURL {
                            Link("Написать в поддержку", destination: url)
                        }
                    }
                }

                Section {
                    Button("Удалить мои данные", role: .destructive) {
                        confirmingDelete = true
                    }
                    .disabled(isDeleting)
                } header: {
                    Text("Данные")
                } footer: {
                    Text("На сервере хранятся только анонимный идентификатор установки, токен уведомлений и ваши направления с порогами цен. Аккаунтов у нас нет.")
                }
            }
            .navigationTitle("О приложении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
            .overlay {
                if isDeleting { ProgressView("Удаляем…").padding().background(.regularMaterial, in: .rect(cornerRadius: 12)) }
            }
            .confirmationDialog("Удалить все данные?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) { Task { await deleteAllData() } }
            } message: {
                Text("Направления будут удалены с сервера и с этого устройства, уведомления прекратятся. Это нельзя отменить.")
            }
            .alert("Данные удалены", isPresented: $didDelete) {
                Button("OK") { dismiss() }
            } message: {
                Text("Направления удалены с сервера и с этого устройства.")
            }
            .alert("Не удалось удалить данные", isPresented: Binding(
                get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    // Удаляет данные на сервере, затем на устройстве. Если сервер недоступен, ничего не трогаем:
    // пользователь увидит ошибку и сможет повторить.
    private func deleteAllData() async {
        isDeleting = true
        defer { isDeleting = false }

        SyncService.shared.cancelPending()          // чтобы не ушла синхронизация во время удаления
        do {
            try await APIClient.shared.deleteDeviceData(installId: InstallID.value)
        } catch {
            errorText = error.localizedDescription
            return
        }

        SyncService.shared.reset()                  // забываем токен и признак синхронизации
        try? context.delete(model: Destination.self) // все направления на устройстве
        SharedStore.save(WidgetSnapshot(destinations: [], updatedAt: Date()))  // очищаем виджет
        InstallID.reset()                           // новый ID, если пользователь начнёт заново
        didDelete = true
    }
}

#Preview {
    AboutView()
}
