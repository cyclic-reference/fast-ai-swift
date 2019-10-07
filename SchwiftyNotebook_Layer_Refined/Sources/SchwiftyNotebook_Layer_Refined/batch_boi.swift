/*
THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
file to edit: batch_boi.ipynb

*/



import TensorFlow
import SchwiftyNotebook_auto_diffy

import Python

public func normalizeFeatureTensor(featureTensor: TensorFloat) -> TensorFloat {
    return TensorFloat(stacking: featureTensor.unstacked(alongAxis: 1)
                                               .map { normalizeTensor(tensor: $0) }, 
                       alongAxis: 1)
}

public struct DataBunch<T> where T: TensorGroup {
    public let trainingDataset: Dataset<T>
    public let validationDataset: Dataset<T>
}

public struct UsedCarBatch {
    public let features: TensorFloat
    public let labels: TensorFloat
}

extension UsedCarBatch: TensorGroup {
    
    public static var _typeList: [TensorDataType] = [
        Float.tensorFlowDataType,
        Float.tensorFlowDataType
    ]
    public static var _unknownShapeList: [TensorShape?] = [nil, nil]
    public var _tensorHandles: [_AnyTensorHandle] {
        fatalError("unimplemented")
    }
    public func _unpackTensorHandles(into address: UnsafeMutablePointer<CTensorHandle>?) {
        address!.advanced(by: 0).initialize(to: features.handle._cTensorHandle)
        address!.advanced(by: 1).initialize(to: labels.handle._cTensorHandle)
    }
    public init(_owning tensorHandles: UnsafePointer<CTensorHandle>?) {
        features = Tensor(handle: TensorHandle(_owning: tensorHandles!.advanced(by: 0).pointee))
        labels = Tensor(handle: TensorHandle(_owning: tensorHandles!.advanced(by: 1).pointee))
    }
    public init<C: RandomAccessCollection>(_handles: C) where C.Element: _AnyTensorHandle {
        fatalError("unimplemented")
    }
}

public extension Sequence where Element == UsedCarBatch {
    var first: UsedCarBatch? {
        return first(where: { _ in true })
    }
}

public extension Dataset where Element == UsedCarBatch {
    init(featuresTensor: TensorFloat, labelsTensor: TensorFloat) {
        self.init(elements: UsedCarBatch(features: featuresTensor, 
                                     labels: labelsTensor))
    }
}

public func reScaleTensor(tensorToRescale: TensorFloat) -> TensorFloat {
    let maxBoi = TensorFloat([tensorToRescale.max()])
    let minBoi = TensorFloat([tensorToRescale.min()])
    return (tensorToRescale - minBoi) / (maxBoi - minBoi)
}

public func reScaleFeatures(featureTensor: TensorFloat, catVars: Set<Int>, contVars: Set<Int>) -> TensorFloat {
    return TensorFloat(stacking: featureTensor.unstacked(alongAxis: 1).enumerated()
                                               .map { (index, tensi) in 
                                                     if(catVars.contains(index)){
                                                        return reScaleTensor(tensorToRescale: tensi)
                                                     } else if (contVars.contains(index)){
                                                       return normalizeTensor(tensor: tensi) 
                                                     } else {
                                                       return tensi
                                                     }
                                               }, 
                       alongAxis: 1)
}

let carDataYCSV = "/home/ubuntu/.machine-learning/data/car_stuff/pakistan_car_labels.csv"
let carDataXCSV = "/home/ubuntu/.machine-learning/data/car_stuff/pakistan_car_x_data.csv"

public let numpy = Python.import("numpy")

func createDataSet(featureTensor: TensorFloat, 
                   labelTensor: TensorFloat, 
                   batchSize: Int) -> Dataset<UsedCarBatch> {
    return Dataset(featuresTensor: featureTensor, labelsTensor: labelTensor)
                    .batched(batchSize)
                    .shuffled(sampleCount: 64, 
                              randomSeed: 69, 
                              reshuffleForEachIterator: true)
}

public func fetchUsedCarDataBunch(validationSize: Double = 0.2,
                             batchSize: Int = 1028
                            ) -> DataBunch<UsedCarBatch> {
    let usedCarFeaturesArray = numpy.loadtxt(carDataXCSV, 
                                delimiter: ",", 
                                skiprows: 1, 
                                usecols: Array(1...8), 
                                dtype: Float.numpyScalarTypes.first!)
    let categoricalVariableSet: Set = [0,1,2,3,4,5]
    let continousVariableSet: Set = [6,7]
    let usedCarFeatureTensor = reScaleFeatures(featureTensor: TensorFloat(numpy: usedCarFeaturesArray)!, 
                                               catVars: categoricalVariableSet, 
                                               contVars: continousVariableSet)
    
    let usedCarPrices = numpy.loadtxt(carDataYCSV, 
                                delimiter: ",", 
                                skiprows: 0, 
                                usecols: [1], 
                                dtype: Float.numpyScalarTypes.first!)
    let usedCarLabelsTensor = TensorFloat(numpy: usedCarPrices)!
    
    let numberOfUsedCars = usedCarFeatureTensor.shape[0]
    let numberOfUsedCarFeatures = usedCarFeatureTensor.shape[1]
    
    let validationDatasetSize = Int32(floor(validationSize * Double(numberOfUsedCars)))
    let trainingDataSetSize = Int32(numberOfUsedCars) - validationDatasetSize
    
    
    let splitFeatures = usedCarFeatureTensor
                                .split(sizes: Tensor<Int32>([validationDatasetSize, trainingDataSetSize]), 
                                       alongAxis: 0)
    let splitLabels = usedCarLabelsTensor
                            .split(sizes: Tensor<Int32>([validationDatasetSize, trainingDataSetSize]), 
                                   alongAxis: 0)
    
    let validationDataSet = createDataSet(featureTensor: splitFeatures[0],
                                        labelTensor: splitLabels[0], batchSize: batchSize)
    let trainingDataSet = createDataSet(featureTensor: splitFeatures[1],
                                        labelTensor: splitLabels[1], batchSize: batchSize)
    return DataBunch(trainingDataset: trainingDataSet, validationDataset: validationDataSet)
}
