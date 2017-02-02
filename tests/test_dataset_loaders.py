
import numpy as np
import os
import sys
import unittest

path = os.path.join(os.path.dirname(__file__), os.pardir, 'scripts')
sys.path.append(os.path.abspath(path))

import dataset_loaders

class TestRiskDatasetLoader(unittest.TestCase):

    def test_risk_dataset_loader(self):
        input_filepath = os.path.abspath(os.path.join(
            os.path.dirname(__file__), 'data', 'datasets', 'debug.h5'))
        data = dataset_loaders.risk_dataset_loader(
            input_filepath, train_split=.8)
        keys = ['x_train', 'y_train', 'x_val', 'y_val']
        for k in keys:
            self.assertTrue(k in data)
        num_train = float(len(data['x_train']))
        num_val = len(data['x_val'])
        self.assertAlmostEqual(num_train / (num_train + num_val), .8, 2)

    def test_normalization(self):
        input_filepath = os.path.abspath(os.path.join(
            os.path.dirname(__file__), 'data', 'datasets', 'debug.h5'))
        data_unnorm = dataset_loaders.risk_dataset_loader(
            input_filepath, normalize=False)
        data_norm = dataset_loaders.risk_dataset_loader(
            input_filepath, normalize=True)
        
        mean = np.mean(data_unnorm['x_train'], axis=0)
        expected = (data_unnorm['x_train'] - mean)
        std = np.std(expected, axis=0)
        std[std < 1e-8] = 1
        expected /= std

        actual = data_norm['x_train']
        np.testing.assert_array_equal(expected, actual)

if __name__ == '__main__':
    unittest.main()