//
//  ContentView.swift
//  Instafilter
//
//  Created by Marat Fakhrizhanov on 29.10.2024.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI

struct ContentView: View {
    
    @State private var processedImage: Image? // картинка которую выберем/массив
    @State private var filterIntensity = 0.5 // параметр интенсивности ДАБЛ
    @State private var filterRadius = 12.0//параметр
    @State private var filterScale = 1.0
    @State private var selectedItem: PhotosPickerItem?// выбранная картинка
    @State private var showingFilters = false // показать конфирматион диалог
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone() // фильтр по умолчанию - сепия
    let context = CIContext()
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) { // вызывается для выбора фото из галереи
                    
                    if let processedImage { // если тру - есть фото, то показываем его
                        processedImage
                            .resizable()
                            .scaledToFit()
                        
                        
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo") ) // заглушка если нет фото
                    }
                }.buttonStyle(.plain) // кнопка в серый цвет красится
                    .onChange(of: selectedItem, loadImage)// по изменении картинки из нил в картинку - вызовется метод
                
                if processedImage != nil { // если  нет картинки - не показывает слайдеры
              
                    Spacer()
                    VStack{
                        HStack {
                            Text("Intensity")
                            Slider(value: $filterIntensity) // слайдер интенсивности  , остальные слайдеры так же
                                .onChange(of: filterIntensity, applyProcessing)
                        }
                        HStack {
                            Text("Radius")
                            Slider(value: $filterRadius, in: 0...1000)
                                .onChange(of: filterRadius, applyProcessing)
                        }
                        HStack {
                            Text("Scale")
                            Slider(value: $filterScale, in: 0...100, step: 0.5)
                                .onChange(of: filterScale, applyProcessing)
                        }
                    }
                HStack {
                    Button("Change filter", action: changeFilter) // кнопка вызова меню
                    
                    Spacer()
                    
                    Button("del image", action: {processedImage = nil; selectedItem = nil}) // кнопка сброса изображения
                }
                
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) { // кнопки меню
                Button("Crystallize") { setFilter(CIFilter.affineTile()) }
                Button("Edges") { setFilter(CIFilter.areaMinMaxRed()) }
                Button("Gaussian Blur") { setFilter(CIFilter.bloom()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task { // аваит , ждем изображение в фоне
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return } // делаем дату из выбранного файла из за того что бедет UIKIT
            
            
            guard let inputImage = UIImage(data: imageData) else { return } // получает картинку из даты
            
            let beginImage = CIImage(image: inputImage) // получаем новый тип картинки из ЮАКИТ картинки
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)// применяем фильтр к картинке
            applyProcessing() // работаем с ключами фильтра
        }
    }
    
    func applyProcessing() {
        
        let inputKeys = currentFilter.inputKeys // все ключи фильра выбранного

        //Если есть данный ключ, то передаем в него значение полученное в слайдере и применяем изменения
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage) // отдаем картинку в SWIFT UI
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter // обновляем фильтр после выбора его в меню и загружаем изображение с ним и его ключами
        loadImage()
    }
    
    
}
#Preview {
    ContentView()
}
