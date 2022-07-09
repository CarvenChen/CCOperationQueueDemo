//
//  ViewController.m
//  CCOperationQueueDemo
//
//  Created by Carven on 2022/7/8.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self actionOnNwtWork];//网上最多的demo
//    [self realNetworkAction];//网上demo实际使用效果
//    [self semaphoreAction];//信号量方案
//    [self semaphoreAction_adjust];//出现死锁的信号量方案
    [self semaphoreAction_final];//最终版信号量方案
}

- (void)actionOnNwtWork {
    __block NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    NSLog(@"===--- op1请求");
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op1请求开始");
        sleep(3);
    }];
    
    NSLog(@"===--- op2请求");
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op2请求开始");
        sleep(3);
    }];
    
    NSLog(@"===--- op3请求");
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op3请求开始");
        sleep(3);
    }];
    
    [op2 addDependency:op1];
    [op3 addDependency:op2];
    
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
}


- (void)realNetworkAction {
    __block NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    NSLog(@"===--- op1请求");
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op1请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.baidu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op1请求结束");
        }] resume];
    }];
    
    NSLog(@"===--- op2请求");
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op2请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.sina.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op2请求结束");
        }] resume];
    }];
    
    NSLog(@"===--- op3请求");
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"===--- op3请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.qq.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op3请求结束");
        }] resume];
    }];
    
    [op2 addDependency:op1];
    [op3 addDependency:op2];
    
    [queue addOperation:op1];
    [queue addOperation:op2];
    [queue addOperation:op3];
}

- (void)semaphoreAction {
    
    /// 信号量 为 0，则该函数就会一直等待，也就是不返回（相当于阻塞当前线程）
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    /// 创建线程
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block BOOL result = YES;
    NSLog(@"===--- op1请求");
    dispatch_async(queue, ^{
        NSLog(@"===--- op1请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.baidu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op1请求结束");
            dispatch_semaphore_signal(semaphore);/// 请求完成订阅信号
        }] resume];
    });
    /// 等待信号
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"===--- op2请求");
    
    dispatch_async(queue, ^{
        
        if (!result) {
            dispatch_semaphore_signal(semaphore);
            NSLog(@"===--- op2请求拒绝");
            return;
        }
        NSLog(@"===--- op2请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.sina.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op2请求结束");
            dispatch_semaphore_signal(semaphore);
        }] resume];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"===--- op3请求");
    dispatch_async(queue, ^{
        if (!result) {
            dispatch_semaphore_signal(semaphore);
            NSLog(@"===--- op3请求拒绝");
            return;
        }
        NSLog(@"===--- op3请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.qq.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op3请求结束");
            dispatch_semaphore_signal(semaphore);
        }] resume];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"===--- 结束");
}

- (void)semaphoreAction_adjust {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block BOOL result = YES;
    NSLog(@"===--- op1请求");
    dispatch_async(queue, ^{
        NSLog(@"===--- op1请求开始");
        [self requestAction:^(BOOL result) {
            NSLog(@"===--- op1请求结束");
            dispatch_semaphore_signal(semaphore);
        }];
    });
    /// 等待信号
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"===--- op2请求");
    dispatch_async(queue, ^{
        if (!result) {
            dispatch_semaphore_signal(semaphore);
            NSLog(@"===--- op2请求拒绝");
            return;
        }
        NSLog(@"===--- op2请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.sina.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op2请求结束");
            dispatch_semaphore_signal(semaphore);
        }] resume];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"===--- 结束");
}


- (void)semaphoreAction_final {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block BOOL result = YES;
    NSLog(@"===--- op1请求");
    dispatch_async(queue, ^{
        NSLog(@"===--- op1请求开始");
        [self requestAction:^(BOOL result) {
            NSLog(@"===--- op1请求结束 结果：%@", result ? @"YES" : @"NO");
            dispatch_semaphore_signal(semaphore);
        }];
    });
    /// 等待信号
    NSLog(@"===--- op2请求");
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (!result) {
            dispatch_semaphore_signal(semaphore);
            NSLog(@"===--- op2请求拒绝");
            return;
        }
        NSLog(@"===--- op2请求开始");
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.sina.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            NSLog(@"===--- op2请求结束");
            dispatch_semaphore_signal(semaphore);
        }] resume];
    });

    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"===--- 结束 %@", result ? @"YES" : @"NO");
    });
}

- (void)requestAction:(void(^)(BOOL result))block {
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://www.baidu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(error == nil);
            }
        });
    }] resume];
}

@end
